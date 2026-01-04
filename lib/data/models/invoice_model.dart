import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum InvoiceStatus {
  paid,
  pending,
  overdue,
  draft,
  cancelled;

  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'Pago';
      case InvoiceStatus.pending:
        return 'Pendente';
      case InvoiceStatus.overdue:
        return 'Atrasado';
      case InvoiceStatus.draft:
        return 'Rascunho';
      case InvoiceStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.paid:
        return AppColors.statusPaid;
      case InvoiceStatus.pending:
        return AppColors.statusPending;
      case InvoiceStatus.overdue:
        return AppColors.statusOverdue;
      case InvoiceStatus.draft:
        return AppColors.statusDraft;
      case InvoiceStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

class InvoiceItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final bool isValid; // For AI validation
  final String? error; // For AI validation

  const InvoiceItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.isValid = true,
    this.error,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItem.mock({
    String? id,
    required String name,
    required double unitPrice,
    int quantity = 1,
    bool isValid = true,
  }) {
    return InvoiceItem(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
      isValid: isValid,
      error: isValid ? null : 'Please provide a more specific description.',
    );
  }

  InvoiceItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    bool? isValid,
    String? error,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      isValid: isValid ?? this.isValid,
      error: error ?? this.error,
    );
  }
}

class Invoice {
  final String id;
  final String number;
  final String clientName;
  final double amount;
  final DateTime date;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String? clientAvatarUrl;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.amount,
    required this.date,
    required this.dueDate,
    required this.status,
    this.clientAvatarUrl,
    this.items = const [],
  });

  // Factory for creating mock data easily
  factory Invoice.mock({
    required String id,
    required String number,
    required String clientName,
    required double amount,
    required InvoiceStatus status,
    int daysAgo = 0,
  }) {
    final now = DateTime.now();
    return Invoice(
      id: id,
      number: number,
      clientName: clientName,
      amount: amount,
      date: now.subtract(Duration(days: daysAgo)),
      dueDate: now.add(const Duration(days: 14)),
      status: status,
    );
  }

  // Convert to Map for database storage
  // Note: This is a simplified version that maps to the database structure
  // clientName needs to be resolved to clientId before saving
  Map<String, dynamic> toMap({String? clientId}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': id,
      'clientId': clientId ?? '', // Must be provided
      'invoiceNumber': number,
      'date': date.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.name,
      'subtotal': amount, // Simplified: using amount as subtotal
      'taxRate': 0.0,
      'taxAmount': 0.0,
      'discountAmount': 0.0,
      'total': amount,
      'currency': 'USD',
      'notes': null,
      'createdAt': now,
      'updatedAt': now,
      'syncStatus': 0,
    };
  }

  // Create from Map (database)
  // Note: clientName will need to be resolved from clientId via a join or lookup
  factory Invoice.fromMap(
    Map<String, dynamic> map, {
    String? clientName,
  }) {
    return Invoice(
      id: map['id'] as String,
      number: map['invoiceNumber'] as String,
      clientName: clientName ?? 'Unknown Client',
      amount: (map['total'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      clientAvatarUrl: null,
      items: const [], // Items would be loaded separately from invoice_items table
    );
  }
}
