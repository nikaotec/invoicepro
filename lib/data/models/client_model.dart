import 'package:flutter/material.dart';

enum ClientStatus {
  active,
  overdue,
  limitReached,
  newLead;

  String get label {
    switch (this) {
      case ClientStatus.active:
        return 'Active';
      case ClientStatus.overdue:
        return 'Overdue';
      case ClientStatus.limitReached:
        return 'Limit Reached';
      case ClientStatus.newLead:
        return 'New Lead';
    }
  }

  Color get color {
    switch (this) {
      case ClientStatus.active:
        return const Color(0xFF10B981); // Emerald
      case ClientStatus.overdue:
        return const Color(0xFFEF4444); // Red
      case ClientStatus.limitReached:
        return const Color(0xFFF97316); // Orange
      case ClientStatus.newLead:
        return const Color(0xFF3B82F6); // Blue
    }
  }
}

class Client {
  final String id;
  final String name;
  final String company;
  final String email;
  final ClientStatus status;
  final double totalBilled;
  final String lastActivityOrInvoice; // "Oct 22, 2024" or "2 days ago"
  final String initials;
  final List<Color> avatarGradient;
  final String? creditLeft; // Optional, for limit reached

  const Client({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.status,
    required this.totalBilled,
    required this.lastActivityOrInvoice,
    required this.initials,
    required this.avatarGradient,
    this.creditLeft,
  });

  // Factory for mock data creation helper
  factory Client.mock({
    required String id,
    required String name,
    required String company,
    required ClientStatus status,
    required double totalBilled,
    required String lastActivity,
    required String initials,
    required List<Color> gradient,
    String? creditLeft,
  }) {
    return Client(
      id: id,
      name: name,
      company: company,
      email: '${name.replaceAll(' ', '.').toLowerCase()}@example.com',
      status: status,
      totalBilled: totalBilled,
      lastActivityOrInvoice: lastActivity,
      initials: initials,
      avatarGradient: gradient,
      creditLeft: creditLeft,
    );
  }

  // Convert to Map for database storage
  // Note: Some fields (company, status, totalBilled, etc.) are UI-specific
  // and will be stored in a simplified way or calculated from invoices
  Map<String, dynamic> toMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': '', // Can be extended later
      'taxId': null,
      'address': company, // Using company field for address temporarily
      'city': null,
      'state': null,
      'country': null,
      'postalCode': null,
      'createdAt': now,
      'updatedAt': now,
      'syncStatus': 0,
    };
  }

  // Create from Map (database)
  factory Client.fromMap(Map<String, dynamic> map) {
    // Default gradient colors
    final gradientColors = [const Color(0xFFE0E7FF), const Color(0xFFDBEAFE)];
    
    // Extract initials from name
    final name = map['name'] as String;
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '??';

    return Client(
      id: map['id'] as String,
      name: name,
      company: map['address'] as String? ?? '', // Using address field for company
      email: map['email'] as String,
      status: ClientStatus.newLead, // Default status, can be calculated from invoices
      totalBilled: 0.0, // Will be calculated from invoices
      lastActivityOrInvoice: '',
      initials: initials,
      avatarGradient: gradientColors,
      creditLeft: null,
    );
  }
}
