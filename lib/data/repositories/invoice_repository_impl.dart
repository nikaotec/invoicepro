import 'package:sqflite/sqflite.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/database_helper.dart';

/// Implementation of InvoiceRepository using SQLite
class InvoiceRepositoryImpl implements InvoiceRepository {
  final DatabaseHelper _dbHelper;

  InvoiceRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<({List<Invoice>? data, Failure? error})> getInvoices() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvoices,
        orderBy: 'createdAt DESC',
      );

      final invoices = <Invoice>[];
      for (final map in maps) {
        final invoice = await _mapToDomainEntity(map);
        if (invoice != null) {
          invoices.add(invoice);
        }
      }

      return (data: invoices, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get invoices: ${e.toString()}')
      );
    }
  }

  @override
  Future<({List<Invoice>? data, Failure? error})> getRecentInvoices({
    int limit = 10,
  }) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvoices,
        orderBy: 'createdAt DESC',
        limit: limit,
      );

      final invoices = <Invoice>[];
      for (final map in maps) {
        final invoice = await _mapToDomainEntity(map);
        if (invoice != null) {
          invoices.add(invoice);
        }
      }

      return (data: invoices, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get recent invoices: ${e.toString()}')
      );
    }
  }

  @override
  Future<({Invoice? data, Failure? error})> getInvoiceById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvoices,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return (
          data: null,
          error: NotFoundFailure('Invoice with id $id not found')
        );
      }

      final invoice = await _mapToDomainEntity(maps.first);
      if (invoice == null) {
        return (
          data: null,
          error: DatabaseFailure('Failed to map invoice data')
        );
      }

      return (data: invoice, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get invoice: ${e.toString()}')
      );
    }
  }

  @override
  Future<({String? invoiceId, Failure? error})> createInvoice(
    Invoice invoice,
  ) async {
    try {
      final db = await _dbHelper.database;

      // Map domain entity to database map
      final invoiceMap = _mapToDatabase(invoice);

      await db.insert(
        DatabaseHelper.tableInvoices,
        invoiceMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save invoice items
      if (invoice.items.isNotEmpty) {
        final batch = db.batch();
        for (final item in invoice.items) {
          batch.insert(
            DatabaseHelper.tableInvoiceItems,
            {
              'id': item.id,
              'invoiceId': invoice.id,
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'total': item.total,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      return (invoiceId: invoice.id, error: null);
    } catch (e) {
      return (
        invoiceId: null,
        error: DatabaseFailure('Failed to create invoice: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> updateInvoice(Invoice invoice) async {
    try {
      final db = await _dbHelper.database;
      final invoiceMap = _mapToDatabase(invoice);

      final count = await db.update(
        DatabaseHelper.tableInvoices,
        invoiceMap,
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Invoice with id ${invoice.id} not found')
        );
      }

      // Update invoice items
      // Delete existing items and insert new ones
      await db.delete(
        DatabaseHelper.tableInvoiceItems,
        where: 'invoiceId = ?',
        whereArgs: [invoice.id],
      );

      if (invoice.items.isNotEmpty) {
        final batch = db.batch();
        for (final item in invoice.items) {
          batch.insert(
            DatabaseHelper.tableInvoiceItems,
            {
              'id': item.id,
              'invoiceId': invoice.id,
              'description': item.description,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'total': item.total,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to update invoice: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> deleteInvoice(String id) async {
    try {
      final db = await _dbHelper.database;
      // Items will be deleted automatically due to CASCADE
      final count = await db.delete(
        DatabaseHelper.tableInvoices,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Invoice with id $id not found')
        );
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to delete invoice: ${e.toString()}')
      );
    }
  }

  @override
  Future<({Map<String, dynamic>? data, Failure? error})> getDashboardStats() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvoices,
      );

      if (maps.isEmpty) {
        return (
          data: {
            'totalRevenue': 0.00,
            'pendingAmount': 0.00,
            'overdueAmount': 0.00,
            'invoicesCount': 0,
            'clientsCount': 0,
          },
          error: null
        );
      }

      double totalRevenue = 0.0;
      double pendingAmount = 0.0;
      double overdueAmount = 0.0;
      final now = DateTime.now();
      final clientIds = <String>{};

      for (final map in maps) {
        final status = map['status'] as String;
        final total = (map['total'] as num).toDouble();
        final dueDate = DateTime.fromMillisecondsSinceEpoch(
          map['dueDate'] as int,
        );
        final clientId = map['clientId'] as String;

        clientIds.add(clientId);

        if (status == InvoiceStatus.paid.name) {
          totalRevenue += total;
        } else if (status == InvoiceStatus.sent.name || 
                   status == InvoiceStatus.draft.name) {
          pendingAmount += total;
          if (dueDate.isBefore(now)) {
            overdueAmount += total;
          }
        } else if (status == InvoiceStatus.overdue.name) {
          overdueAmount += total;
        }
      }

      return (
        data: {
          'totalRevenue': totalRevenue,
          'pendingAmount': pendingAmount,
          'overdueAmount': overdueAmount,
          'invoicesCount': maps.length,
          'clientsCount': clientIds.length,
        },
        error: null
      );
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get dashboard stats: ${e.toString()}')
      );
    }
  }

  @override
  Future<({List<Invoice>? data, Failure? error})> searchInvoices(
    String query,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableInvoices,
        where: 'invoiceNumber LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'createdAt DESC',
      );

      final invoices = <Invoice>[];
      for (final map in maps) {
        final invoice = await _mapToDomainEntity(map);
        if (invoice != null) {
          invoices.add(invoice);
        }
      }

      return (data: invoices, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to search invoices: ${e.toString()}')
      );
    }
  }

  /// Map database row to domain entity
  Future<Invoice?> _mapToDomainEntity(Map<String, dynamic> map) async {
    try {
      // Get invoice items
      final db = await _dbHelper.database;
      final itemsMaps = await db.query(
        DatabaseHelper.tableInvoiceItems,
        where: 'invoiceId = ?',
        whereArgs: [map['id'] as String],
      );

      final items = itemsMaps.map((itemMap) {
        return InvoiceItem(
          id: itemMap['id'] as String,
          description: itemMap['description'] as String,
          quantity: (itemMap['quantity'] as num).toDouble(),
          unitPrice: (itemMap['unitPrice'] as num).toDouble(),
          total: (itemMap['total'] as num).toDouble(),
        );
      }).toList();

      return Invoice(
        id: map['id'] as String,
        clientId: map['clientId'] as String,
        invoiceNumber: map['invoiceNumber'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
        status: InvoiceStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => InvoiceStatus.draft,
        ),
        items: items,
        subtotal: (map['subtotal'] as num).toDouble(),
        taxRate: (map['taxRate'] as num).toDouble(),
        taxAmount: (map['taxAmount'] as num).toDouble(),
        discountAmount: (map['discountAmount'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        currency: map['currency'] as String? ?? 'USD',
        notes: map['notes'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
    } catch (e) {
      return null;
    }
  }

  /// Map domain entity to database row
  Map<String, dynamic> _mapToDatabase(Invoice invoice) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': invoice.id,
      'clientId': invoice.clientId,
      'invoiceNumber': invoice.invoiceNumber,
      'date': invoice.date.millisecondsSinceEpoch,
      'dueDate': invoice.dueDate.millisecondsSinceEpoch,
      'status': invoice.status.name,
      'subtotal': invoice.subtotal,
      'taxRate': invoice.taxRate,
      'taxAmount': invoice.taxAmount,
      'discountAmount': invoice.discountAmount,
      'total': invoice.total,
      'currency': invoice.currency,
      'notes': invoice.notes,
      'createdAt': invoice.createdAt.millisecondsSinceEpoch,
      'updatedAt': now,
      'syncStatus': 0,
    };
  }
}

