import 'package:sqflite/sqflite.dart';
import '../models/invoice_model.dart';
import '../datasources/local/database_helper.dart';
import 'client_service.dart';

class InvoiceService {
  final DatabaseHelper _dbHelper;
  final ClientService _clientService;

  InvoiceService({
    DatabaseHelper? dbHelper,
    ClientService? clientService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _clientService = clientService ?? ClientService();

  // Get recent invoices (last 10)
  Future<List<Invoice>> getRecentInvoices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableInvoices,
      orderBy: 'createdAt DESC',
      limit: 10,
    );

    if (maps.isEmpty) {
      return [];
    }

    // Load client names for each invoice
    final invoices = <Invoice>[];
    for (final map in maps) {
      final clientId = map['clientId'] as String;
      
      // Get client name
      String clientName = 'Unknown Client';
      try {
        final clients = await _clientService.getClients();
        if (clients.isNotEmpty) {
          final client = clients.firstWhere(
            (c) => c.id == clientId,
            orElse: () => clients.first,
          );
          clientName = client.name;
        }
      } catch (e) {
        // If client not found, use default name
      }

      invoices.add(Invoice.fromMap(map, clientName: clientName));
    }

    return invoices;
  }

  Future<String> createInvoice(Invoice invoice, {String? clientId}) async {
    final db = await _dbHelper.database;
    
    // If clientId not provided, try to find it by clientName
    String? resolvedClientId = clientId;
    if (resolvedClientId == null || resolvedClientId.isEmpty) {
      final clients = await _clientService.getClients();
      if (clients.isNotEmpty) {
        try {
          final client = clients.firstWhere(
            (c) => c.name == invoice.clientName,
          );
          resolvedClientId = client.id;
        } catch (e) {
          // If not found, use first client as fallback
          resolvedClientId = clients.first.id;
        }
      }
    }

    if (resolvedClientId == null || resolvedClientId.isEmpty) {
      throw Exception('Client ID is required to create invoice');
    }

    await db.insert(
      DatabaseHelper.tableInvoices,
      invoice.toMap(clientId: resolvedClientId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return invoice.id;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await _dbHelper.database;

    // Get all invoices
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableInvoices,
    );

    if (maps.isEmpty) {
      return {
        'totalRevenue': 0.00,
        'pendingAmount': 0.00,
        'overdueAmount': 0.00,
        'invoicesCount': 0,
        'clientsCount': 0,
      };
    }

    // Calculate stats
    double totalRevenue = 0.0;
    double pendingAmount = 0.0;
    double overdueAmount = 0.0;
    final now = DateTime.now();

    for (final map in maps) {
      final status = map['status'] as String;
      final total = (map['total'] as num).toDouble();
      final dueDate = DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int);

      if (status == InvoiceStatus.paid.name) {
        totalRevenue += total;
      } else if (status == InvoiceStatus.pending.name) {
        pendingAmount += total;
        if (dueDate.isBefore(now)) {
          overdueAmount += total;
        }
      } else if (status == InvoiceStatus.overdue.name) {
        overdueAmount += total;
      }
    }

    // Get unique client count
    final clientIds = maps.map((m) => m['clientId'] as String).toSet();

    return {
      'totalRevenue': totalRevenue,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
      'invoicesCount': maps.length,
      'clientsCount': clientIds.length,
    };
  }

  // Get invoice by ID
  Future<Invoice?> getInvoiceById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableInvoices,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final clientId = map['clientId'] as String;
    
    // Get client name
    String clientName = 'Unknown Client';
    try {
      final clients = await _clientService.getClients();
      if (clients.isNotEmpty) {
        final client = clients.firstWhere(
          (c) => c.id == clientId,
          orElse: () => clients.first,
        );
        clientName = client.name;
      }
    } catch (e) {
      // If client not found, use default name
    }

    return Invoice.fromMap(map, clientName: clientName);
  }

  // Delete invoice
  Future<void> deleteInvoice(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableInvoices,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
