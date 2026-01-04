import '../entities/invoice.dart';

/// Use case for calculating invoice totals
class CalculateInvoiceTotal {
  /// Calculate invoice from items with tax and discount
  InvoiceCalculation calculate({
    required List<InvoiceItem> items,
    double taxRate = 0.0,
    double discountAmount = 0.0,
  }) {
    // Calculate subtotal from all items
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.total);

    // Calculate tax amount
    final taxAmount = subtotal * (taxRate / 100);

    // Calculate final total
    final total = subtotal + taxAmount - discountAmount;

    return InvoiceCalculation(
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      total: total > 0 ? total : 0.0,
    );
  }

  /// Recalculate invoice when items change
  Invoice recalculateInvoice(
    Invoice invoice, {
    List<InvoiceItem>? newItems,
    double? newTaxRate,
    double? newDiscountAmount,
  }) {
    final items = newItems ?? invoice.items;
    final taxRate = newTaxRate ?? invoice.taxRate;
    final discountAmount = newDiscountAmount ?? invoice.discountAmount;

    final calculation = calculate(
      items: items,
      taxRate: taxRate,
      discountAmount: discountAmount,
    );

    return invoice.copyWith(
      items: items,
      subtotal: calculation.subtotal,
      taxRate: taxRate,
      taxAmount: calculation.taxAmount,
      discountAmount: discountAmount,
      total: calculation.total,
      updatedAt: DateTime.now(),
    );
  }
}

/// Result of invoice calculation
class InvoiceCalculation {
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;

  const InvoiceCalculation({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
  });
}
