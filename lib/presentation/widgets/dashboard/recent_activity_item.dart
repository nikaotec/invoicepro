import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/invoice_model.dart';

class RecentActivityItem extends StatelessWidget {
  final Invoice invoice;
  final bool isDark;
  final VoidCallback? onTap;

  const RecentActivityItem({
    super.key,
    required this.invoice,
    required this.isDark,
    required this.onTap,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF8B5CF6), // Violet
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  Color _getAvatarBackgroundColor(String name) {
    final color = _getAvatarColor(name);
    return isDark
        ? color.withOpacity(0.3)
        : color.withOpacity(0.1);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(invoice.clientName);
    final avatarBgColor = _getAvatarBackgroundColor(invoice.clientName);
    final initials = _getInitials(invoice.clientName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2233) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Client Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.items.firstOrNull?.name ?? "Invoice"} • #${invoice.number}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                      .format(invoice.amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isPaid = invoice.status == InvoiceStatus.paid;
    final isOverdue = invoice.status == InvoiceStatus.overdue;

    Color bgColor;
    Color textColor;
    String label;
    Widget? icon;

    if (isPaid) {
      bgColor = isDark
          ? Colors.green[900]!.withOpacity(0.2)
          : Colors.green[50]!;
      textColor = isDark ? Colors.green[400]! : Colors.green[700]!;
      label = 'Paid';
      icon = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.green[500],
          shape: BoxShape.circle,
        ),
      );
    } else if (isOverdue) {
      bgColor = isDark
          ? Colors.red[900]!.withOpacity(0.2)
          : Colors.red[50]!;
      textColor = Colors.red;
      label = 'Overdue';
      icon = Icon(
        Icons.error,
        size: 10,
        color: Colors.red,
      );
    } else {
      bgColor = isDark
          ? Colors.grey[800]!
          : Colors.grey[100]!;
      textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

