import 'package:intl/intl.dart';

const int maxTransactionAmount = 999999999999;

final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final NumberFormat _grouped = NumberFormat.decimalPattern('id_ID');

String formatRupiah(int amount) => _rupiah.format(amount);

String formatRupiahAbsolute(int amount) => formatRupiah(amount.abs());

String formatGrouped(int amount) => _grouped.format(amount);

int? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return null;
  }
  return int.tryParse(digits);
}

String formatPercentage(double value) {
  final rounded = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded%';
}
