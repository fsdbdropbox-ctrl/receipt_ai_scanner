import 'package:intl/intl.dart';

class RegionalFormatter {
  static String formatCurrency(double? amount, String? currencyCode, String locale) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currencyCode != null ? getCurrencySymbol(currencyCode) : '',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime? date, String locale) {
    if (date == null) return 'N/A';
    final formatter = DateFormat.yMMMd(locale);
    return formatter.format(date);
  }

  static String formatNumber(double? number, String locale) {
    if (number == null) return 'N/A';
    final formatter = NumberFormat.decimalPattern(locale);
    return formatter.format(number);
  }

  static String getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currencyCode;
    }
  }
}

