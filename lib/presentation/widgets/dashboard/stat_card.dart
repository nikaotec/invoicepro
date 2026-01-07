import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;
  final bool isPrimary;
  final bool isError;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
    this.isPrimary = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary
            ? null
            : Border.all(
                color: isError
                    ? Colors.red.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPrimary
                  ? Colors.white.withOpacity(0.2)
                  : (isError
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isPrimary
                  ? Colors.white.withOpacity(0.8)
                  : (textColor.withOpacity(0.6)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

