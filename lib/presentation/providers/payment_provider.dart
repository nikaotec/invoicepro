import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/usecases/record_payment_usecase.dart';
import 'payment_repository_provider.dart';
import 'invoice_repository_provider.dart';

/// State for payment operations
class PaymentState {
  final List<Payment> payments;
  final double totalPaid;
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.payments = const [],
    this.totalPaid = 0.0,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<Payment>? payments,
    double? totalPaid,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      totalPaid: totalPaid ?? this.totalPaid,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing payments for an invoice
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _paymentRepository;
  final RecordPaymentUseCase _recordPaymentUseCase;
  final String invoiceId;

  PaymentNotifier({
    required PaymentRepository paymentRepository,
    required InvoiceRepository invoiceRepository,
    required RecordPaymentUseCase recordPaymentUseCase,
    required this.invoiceId,
  })  : _paymentRepository = paymentRepository,
        _recordPaymentUseCase = recordPaymentUseCase,
        super(const PaymentState()) {
    loadPayments();
  }

  /// Load payments for the invoice
  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, error: null);

    final paymentsResult =
        await _paymentRepository.getPaymentsByInvoiceId(invoiceId);
    if (paymentsResult.error != null) {
      state = state.copyWith(
        error: paymentsResult.error!.message,
        isLoading: false,
      );
      return;
    }

    final payments = paymentsResult.data ?? [];
    final totalPaidResult =
        await _paymentRepository.getTotalPaidByInvoiceId(invoiceId);
    final totalPaid = totalPaidResult.totalPaid ?? 0.0;

    state = state.copyWith(
      payments: payments,
      totalPaid: totalPaid,
      isLoading: false,
    );
  }

  /// Record a new payment
  Future<bool> recordPayment({
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _recordPaymentUseCase.execute(
      invoiceId: invoiceId,
      amount: amount,
      method: method,
      date: date,
      notes: notes,
    );

    if (result.error != null) {
      state = state.copyWith(
        error: result.error!.message,
        isLoading: false,
      );
      return false;
    }

    // Reload payments after recording
    await loadPayments();

    return true;
  }

  /// Delete a payment
  Future<bool> deletePayment(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _paymentRepository.deletePayment(paymentId);
    if (result.error != null) {
      state = state.copyWith(
        error: result.error!.message,
        isLoading: false,
      );
      return false;
    }

    // Reload payments after deletion
    await loadPayments();

    return true;
  }

  /// Refresh payments
  Future<void> refresh() async {
    await loadPayments();
  }
}

/// Provider factory for PaymentNotifier
final paymentProvider = StateNotifierProvider.family<PaymentNotifier, PaymentState, String>(
  (ref, invoiceId) {
    return PaymentNotifier(
      paymentRepository: ref.read(paymentRepositoryProvider),
      invoiceRepository: ref.read(invoiceRepositoryProvider),
      recordPaymentUseCase: RecordPaymentUseCase(
        paymentRepository: ref.read(paymentRepositoryProvider),
        invoiceRepository: ref.read(invoiceRepositoryProvider),
      ),
      invoiceId: invoiceId,
    );
  },
);

