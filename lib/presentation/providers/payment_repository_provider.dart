import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../data/repositories/payment_repository_impl.dart';

/// Payment Repository Provider - Dependency Injection
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl();
});


