import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/client_model.dart';
import '../datasources/local/database_helper.dart';

class ClientService {
  final DatabaseHelper _dbHelper;

  ClientService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Initial Mock Data matching the HTML design EXACTLY
  static final List<Client> _initialData = [
    Client.mock(
      id: '1',
      name: 'Sarah Miller',
      company: 'Miller Design Co.',
      status: ClientStatus.active,
      totalBilled: 142500.00,
      lastActivity: 'Oct 22, 2024',
      initials: 'SM',
      gradient: [
        const Color(0xFFDBEAFE),
        const Color(0xFFE0E7FF),
      ], // Blue-100 to Indigo-100
    ),
    Client.mock(
      id: '2',
      name: 'Apex Systems',
      company: 'Enterprise',
      status: ClientStatus.overdue,
      totalBilled: 8240.00,
      lastActivity: 'Sep 15, 2024',
      initials: 'apartment', // Using as Icon identifier
      gradient: [const Color(0xFFF3F4F6), const Color(0xFFF3F4F6)], // Gray
    ),
    Client.mock(
      id: '3',
      name: 'David Bowman',
      company: 'Freelance',
      status: ClientStatus.limitReached,
      totalBilled: 2100.00,
      lastActivity: 'Credit Left: \$0.00',
      initials: 'DB',
      gradient: [
        const Color(0xFFF3E8FF),
        const Color(0xFFFCE7F3),
      ], // Purple-100 to Pink-100
      creditLeft: '\$0.00',
    ),
    Client.mock(
      id: '4',
      name: 'Local Market',
      company: 'Retail',
      status: ClientStatus.newLead,
      totalBilled: 0.00,
      lastActivity: '2 days ago',
      initials: 'storefront', // Icon identifier
      gradient: [const Color(0xFFF3F4F6), const Color(0xFFF3F4F6)], // Gray
    ),
  ];

  Future<List<Client>> getClients() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClients,
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) {
      // If database is empty, seed with initial data
      await _seedInitialData();
      return _initialData;
    }

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<void> _seedInitialData() async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    for (final client in _initialData) {
      batch.insert(
        DatabaseHelper.tableClients,
        client.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Client>> searchClients(String query) async {
    if (query.isEmpty) return getClients();

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableClients,
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  Future<String> addClient(Client client) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableClients,
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return client.id;
  }

  Future<void> removeClient(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableClients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Debug: Clear all clients to test empty state
  Future<void> clearClients() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableClients);
  }

  // Debug: Reset to initial mock data
  Future<void> resetClients() async {
    await clearClients();
    await _seedInitialData();
  }
}
