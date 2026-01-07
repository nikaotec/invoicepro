import '../entities/payment.dart';
import '../../core/errors/failures.dart';

/// Abstract repository interface for Payment operations
/// This follows Clean Architecture principles - domain layer doesn't depend on data layer
abstract class PaymentRepository {
  /// Get all payments for a specific invoice
  Future<({List<Payment>? data, Failure? error})> getPaymentsByInvoiceId(String invoiceId);

  /// Get a payment by ID
  Future<({Payment? data, Failure? error})> getPaymentById(String id);

  /// Create a new payment
  Future<({String? paymentId, Failure? error})> createPayment(Payment payment);

  /// Update an existing payment
  Future<({bool success, Failure? error})> updatePayment(Payment payment);

  /// Delete a payment
  Future<({bool success, Failure? error})> deletePayment(String id);

  /// Get total amount paid for an invoice
  Future<({double? totalPaid, Failure? error})> getTotalPaidByInvoiceId(String invoiceId);
}


