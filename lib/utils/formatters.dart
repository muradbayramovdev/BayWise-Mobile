import 'package:intl/intl.dart';

String formatCurrency(double amount, {String symbol = '₺'}) {
  return '$symbol ${amount.toStringAsFixed(2)}';
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatMonth(DateTime date) {
  return DateFormat('yyyy-MM').format(date);
}

String formatDateInput(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
