import 'package:intl/intl.dart';

/// Currency and number formatting utilities
class CurrencyFormatter {
  /// Format amount as currency with symbol
  static String formatCurrency(
    double amount, {
    String currencyCode = 'USD',
    String? locale,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format amount as currency without symbol
  static String formatAmount(double amount, {String? locale}) {
    final formatter = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount).trim();
  }

  /// Format currency with custom symbol placement
  static String formatCurrencyWithCode(
    double amount,
    String currencyCode, {
    String? locale,
  }) {
    final formattedAmount = formatAmount(amount, locale: locale);
    return '$currencyCode $formattedAmount';
  }

  /// Get currency symbol for code
  static String _getCurrencySymbol(String currencyCode) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'BRL': 'R\$',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'Fr',
      'MXN': 'Mex\$',
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  /// Get full currency name
  static String getCurrencyName(String currencyCode) {
    final names = {
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'BRL': 'Brazilian Real',
      'JPY': 'Japanese Yen',
      'CNY': 'Chinese Yuan',
      'INR': 'Indian Rupee',
      'AUD': 'Australian Dollar',
      'CAD': 'Canadian Dollar',
      'CHF': 'Swiss Franc',
      'MXN': 'Mexican Peso',
    };
    return names[currencyCode] ?? currencyCode;
  }

  /// Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      // Remove currency symbols and whitespace
      final cleaned = value.replaceAll(RegExp(r'[^\d,.-]'), '');
      // Replace comma with dot for decimal
      final normalized = cleaned.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format compact number (1000 -> 1K, 1000000 -> 1M)
  static String formatCompact(double value, {String? locale}) {
    final formatter = NumberFormat.compact(locale: locale ?? 'en_US');
    return formatter.format(value);
  }

  /// Format number with thousand separators
  static String formatNumber(double value, {int decimals = 0}) {
    final formatter = NumberFormat(
      '#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}',
    );
    return formatter.format(value);
  }
}

/// Date formatting utilities
class DateFormatter {
  /// Format date as 'MMM dd, yyyy' (e.g., 'Jan 15, 2024')
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date as 'dd/MM/yyyy'
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy · hh:mm a').format(dateTime);
  }

  /// Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Get relative time (e.g., '2 days ago', 'Just now')
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Check if date is overdue
  static bool isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  /// Get days until/since due date
  static int getDaysUntilDue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(
      DateTime(now.year, now.month, now.day),
    );
    return difference.inDays;
  }
}
