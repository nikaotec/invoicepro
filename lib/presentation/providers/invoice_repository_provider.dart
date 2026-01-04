import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../data/repositories/invoice_repository_impl.dart';

/// Repository Provider - Dependency Injection
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl();
});

