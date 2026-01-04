import 'package:sqflite/sqflite.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/database_helper.dart';

/// Implementation of ClientRepository using SQLite
class ClientRepositoryImpl implements ClientRepository {
  final DatabaseHelper _dbHelper;

  ClientRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Initial mock data for seeding
  static final List<Map<String, dynamic>> _initialData = [
    {
      'id': '1',
      'name': 'Sarah Miller',
      'email': 'sarah.miller@example.com',
      'phone': null,
      'taxId': null,
      'address': 'Miller Design Co.',
      'city': null,
      'state': null,
      'country': null,
      'postalCode': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    },
    {
      'id': '2',
      'name': 'Apex Systems',
      'email': 'contact@apexsystems.com',
      'phone': null,
      'taxId': null,
      'address': 'Enterprise',
      'city': null,
      'state': null,
      'country': null,
      'postalCode': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 45)).millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    },
    {
      'id': '3',
      'name': 'David Bowman',
      'email': 'david.bowman@example.com',
      'phone': null,
      'taxId': null,
      'address': 'Freelance',
      'city': null,
      'state': null,
      'country': null,
      'postalCode': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 20)).millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    },
    {
      'id': '4',
      'name': 'Local Market',
      'email': 'info@localmarket.com',
      'phone': null,
      'taxId': null,
      'address': 'Retail',
      'city': null,
      'state': null,
      'country': null,
      'postalCode': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    },
  ];

  @override
  Future<({List<Client>? data, Failure? error})> getClients() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableClients,
        orderBy: 'createdAt DESC',
      );

      // If database is empty, seed with initial data
      if (maps.isEmpty) {
        await _seedInitialData();
        // Query again after seeding
        final seededMaps = await db.query(
          DatabaseHelper.tableClients,
          orderBy: 'createdAt DESC',
        );
        final clients = seededMaps.map((map) => _mapToDomainEntity(map)).toList();
        return (data: clients, error: null);
      }

      final clients = maps.map((map) => _mapToDomainEntity(map)).toList();
      return (data: clients, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get clients: ${e.toString()}')
      );
    }
  }

  @override
  Future<({Client? data, Failure? error})> getClientById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableClients,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return (
          data: null,
          error: NotFoundFailure('Client with id $id not found')
        );
      }

      return (data: _mapToDomainEntity(maps.first), error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get client: ${e.toString()}')
      );
    }
  }

  @override
  Future<({String? clientId, Failure? error})> createClient(Client client) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        DatabaseHelper.tableClients,
        _mapToDatabase(client),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return (clientId: client.id, error: null);
    } catch (e) {
      return (
        clientId: null,
        error: DatabaseFailure('Failed to create client: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> updateClient(Client client) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        DatabaseHelper.tableClients,
        _mapToDatabase(client),
        where: 'id = ?',
        whereArgs: [client.id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Client with id ${client.id} not found')
        );
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to update client: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> deleteClient(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableClients,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Client with id $id not found')
        );
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to delete client: ${e.toString()}')
      );
    }
  }

  @override
  Future<({List<Client>? data, Failure? error})> searchClients(
    String query,
  ) async {
    try {
      if (query.isEmpty) {
        return getClients();
      }

      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableClients,
        where: 'name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      final clients = maps.map((map) => _mapToDomainEntity(map)).toList();
      return (data: clients, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to search clients: ${e.toString()}')
      );
    }
  }

  /// Seed initial data if database is empty
  Future<void> _seedInitialData() async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final data in _initialData) {
      batch.insert(
        DatabaseHelper.tableClients,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Map database row to domain entity
  Client _mapToDomainEntity(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      taxId: map['taxId'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      postalCode: map['postalCode'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Map domain entity to database row
  Map<String, dynamic> _mapToDatabase(Client client) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': client.id,
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'taxId': client.taxId,
      'address': client.address,
      'city': client.city,
      'state': client.state,
      'country': client.country,
      'postalCode': client.postalCode,
      'createdAt': client.createdAt.millisecondsSinceEpoch,
      'updatedAt': now,
      'syncStatus': 0,
    };
  }
}

