import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currencySymbol) {
    final formatter = NumberFormat('#,##,##0.00');
    return '$currencySymbol${formatter.format(amount)}';
  }

  /// Returns a short word label like "1.23 Lakh", "2.4 Crore", "₹850"
  /// Used as a small subtitle below the main formatted amount.
  static String wordLabel(double amount, String currencySymbol) {
    if (amount == 0) return '${currencySymbol}0';
    if (amount >= 10000000) {
      final v = amount / 10000000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)} Crore';
    } else if (amount >= 100000) {
      final v = amount / 100000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)} Lakh';
    } else if (amount >= 1000) {
      final v = amount / 1000;
      return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)} Thousand';
    }
    return '$currencySymbol${amount.toStringAsFixed(0)}';
  }

  static String formatCompact(double amount, String currencySymbol) {
    if (amount >= 10000000) {
      return '$currencySymbol${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '$currencySymbol${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '$currencySymbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$currencySymbol${amount.toStringAsFixed(0)}';
  }
}

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  static String monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }

  static String fullMonthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class AppConstants {
  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Freelance',
    'Investments',
    'Rental',
    'Previous Month Savings',
    'Gift',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Fuel',
    'Rent',
    'Utilities',
    'Medical',
    'Shopping',
    'Travel',
    'Entertainment',
    'Education',
    'Subscriptions',
    'Other',
  ];

  static const List<String> currencies = ['₹', '\$', '€', '£', '¥', '₩', '₦'];
}
