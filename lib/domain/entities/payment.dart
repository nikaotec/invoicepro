/// Payment method enum
enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  check,
  paypal,
  other;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

/// Payment entity
class Payment {
  final String id;
  final String invoiceId;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? notes;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.date,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  /// Copy with method
  Payment copyWith({
    String? id,
    String? invoiceId,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
