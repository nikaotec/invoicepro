import '../../domain/entities/payment.dart';
import '../datasources/local/database_helper.dart';

/// Payment model for data layer
/// This provides conversion methods between domain entity and database format
class PaymentModel {
  /// Convert Payment entity to database map
  static Map<String, dynamic> toMap(Payment payment) {
    return {
      'id': payment.id,
      'invoiceId': payment.invoiceId,
      'amount': payment.amount,
      'date': payment.date.millisecondsSinceEpoch,
      'method': payment.method.name,
      'notes': payment.notes,
      'createdAt': payment.createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create Payment entity from database map
  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      invoiceId: map['invoiceId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.other,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}


