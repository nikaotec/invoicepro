/// Payment Intent status for online payments
enum PaymentIntentStatus {
  created,
  processing,
  succeeded,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case PaymentIntentStatus.created:
        return 'Created';
      case PaymentIntentStatus.processing:
        return 'Processing';
      case PaymentIntentStatus.succeeded:
        return 'Succeeded';
      case PaymentIntentStatus.failed:
        return 'Failed';
      case PaymentIntentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Payment Gateway type
enum PaymentGateway {
  stripe,
  paypal;

  String get displayName {
    switch (this) {
      case PaymentGateway.stripe:
        return 'Stripe';
      case PaymentGateway.paypal:
        return 'PayPal';
    }
  }
}

/// Payment Intent entity for online payments
class PaymentIntent {
  final String id;
  final String invoiceId;
  final PaymentGateway gateway;
  final String? gatewayPaymentId; // Stripe Payment Intent ID or PayPal Order ID
  final double amount;
  final String currency;
  final PaymentIntentStatus status;
  final String? clientSecret; // For Stripe
  final String? approvalUrl; // For PayPal
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PaymentIntent({
    required this.id,
    required this.invoiceId,
    required this.gateway,
    this.gatewayPaymentId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.clientSecret,
    this.approvalUrl,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  PaymentIntent copyWith({
    String? id,
    String? invoiceId,
    PaymentGateway? gateway,
    String? gatewayPaymentId,
    double? amount,
    String? currency,
    PaymentIntentStatus? status,
    String? clientSecret,
    String? approvalUrl,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return PaymentIntent(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      gateway: gateway ?? this.gateway,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      clientSecret: clientSecret ?? this.clientSecret,
      approvalUrl: approvalUrl ?? this.approvalUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

