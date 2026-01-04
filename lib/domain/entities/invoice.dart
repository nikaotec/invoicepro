/// Invoice status enum
enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Core invoice domain entity
class Invoice {
  final String id;
  final String clientId;
  final String invoiceNumber;
  final DateTime date;
  final DateTime dueDate;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String currency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.clientId,
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.currency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if invoice is overdue
  bool get isOverdue {
    return status != InvoiceStatus.paid &&
        status != InvoiceStatus.cancelled &&
        dueDate.isBefore(DateTime.now());
  }

  /// Get days until/since due date
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(
      DateTime(now.year, now.month, now.day),
    );
    return difference.inDays;
  }

  /// Copy with method for immutability
  Invoice copyWith({
    String? id,
    String? clientId,
    String? invoiceNumber,
    DateTime? date,
    DateTime? dueDate,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? total,
    String? currency,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Invoice item entity
class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  /// Calculate total for this item
  static double calculateTotal(double quantity, double unitPrice) {
    return quantity * unitPrice;
  }

  /// Copy with method
  InvoiceItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}
