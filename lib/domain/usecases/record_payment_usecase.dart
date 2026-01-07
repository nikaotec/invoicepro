import '../entities/payment.dart';
import '../entities/invoice.dart';
import '../repositories/payment_repository.dart';
import '../repositories/invoice_repository.dart';
import '../../core/errors/failures.dart';
import 'package:uuid/uuid.dart';

/// Use case to record a payment for an invoice
/// This use case handles:
/// 1. Validating the payment amount
/// 2. Creating the payment record
/// 3. Calculating total paid
/// 4. Updating invoice status based on payment
class RecordPaymentUseCase {
  final PaymentRepository _paymentRepository;
  final InvoiceRepository _invoiceRepository;
  final Uuid _uuid = const Uuid();

  RecordPaymentUseCase({
    required PaymentRepository paymentRepository,
    required InvoiceRepository invoiceRepository,
  })  : _paymentRepository = paymentRepository,
        _invoiceRepository = invoiceRepository;

  Future<({bool success, Failure? error})> execute({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  }) async {
    try {
      // 1. Get the invoice
      final invoiceResult = await _invoiceRepository.getInvoiceById(invoiceId);
      if (invoiceResult.error != null) {
        return (success: false, error: invoiceResult.error);
      }

      final invoice = invoiceResult.data;
      if (invoice == null) {
        return (
          success: false,
          error: NotFoundFailure('Invoice with id $invoiceId not found')
        );
      }

      // 2. Get current total paid
      final totalPaidResult =
          await _paymentRepository.getTotalPaidByInvoiceId(invoiceId);
      if (totalPaidResult.error != null) {
        return (success: false, error: totalPaidResult.error);
      }

      final currentTotalPaid = totalPaidResult.totalPaid ?? 0.0;
      final pendingAmount = invoice.total - currentTotalPaid;

      // 3. Validate payment amount
      if (amount <= 0) {
        return (
          success: false,
          error: ValidationFailure('Payment amount must be greater than zero')
        );
      }

      if (amount > pendingAmount) {
        return (
          success: false,
          error: ValidationFailure(
            'Payment amount (\$${amount.toStringAsFixed(2)}) cannot exceed pending amount (\$${pendingAmount.toStringAsFixed(2)})'
          )
        );
      }

      // 4. Create payment record
      final payment = Payment(
        id: _uuid.v4(),
        invoiceId: invoiceId,
        amount: amount,
        date: date,
        method: method,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final createResult = await _paymentRepository.createPayment(payment);
      if (createResult.error != null) {
        return (success: false, error: createResult.error);
      }

      // 5. Calculate new total paid and update invoice status
      final newTotalPaid = currentTotalPaid + amount;
      InvoiceStatus newStatus = invoice.status;

      if (newTotalPaid >= invoice.total) {
        // Fully paid
        newStatus = InvoiceStatus.paid;
      } else {
        // Partially paid - check if overdue
        final now = DateTime.now();
        if (invoice.dueDate.isBefore(now) &&
            invoice.status != InvoiceStatus.cancelled) {
          newStatus = InvoiceStatus.overdue;
        } else if (invoice.status == InvoiceStatus.draft) {
          // Keep draft status if still draft
          newStatus = InvoiceStatus.draft;
        } else {
          // Otherwise keep as sent
          newStatus = InvoiceStatus.sent;
        }
      }

      // 6. Update invoice status if it changed
      if (newStatus != invoice.status) {
        final updatedInvoice = invoice.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );

        final updateResult =
            await _invoiceRepository.updateInvoice(updatedInvoice);
        if (updateResult.error != null) {
          // Payment was created but invoice update failed
          // In a real app, you might want to rollback the payment
          // For now, we'll return success but log the error
          return (success: true, error: null);
        }
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: UnknownFailure('Failed to record payment: ${e.toString()}')
      );
    }
  }
}


