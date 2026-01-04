import '../entities/invoice.dart';
import '../../core/errors/failures.dart';

/// Abstract repository interface for Invoice operations
/// This follows Clean Architecture principles - domain layer doesn't depend on data layer
abstract class InvoiceRepository {
  /// Get all invoices
  Future<({List<Invoice>? data, Failure? error})> getInvoices();

  /// Get recent invoices (last N)
  Future<({List<Invoice>? data, Failure? error})> getRecentInvoices({int limit = 10});

  /// Get invoice by ID
  Future<({Invoice? data, Failure? error})> getInvoiceById(String id);

  /// Create a new invoice
  Future<({String? invoiceId, Failure? error})> createInvoice(Invoice invoice);

  /// Update an existing invoice
  Future<({bool success, Failure? error})> updateInvoice(Invoice invoice);

  /// Delete an invoice
  Future<({bool success, Failure? error})> deleteInvoice(String id);

  /// Get dashboard statistics
  Future<({Map<String, dynamic>? data, Failure? error})> getDashboardStats();

  /// Search invoices by query
  Future<({List<Invoice>? data, Failure? error})> searchInvoices(String query);
}

