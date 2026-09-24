import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _idr = NumberFormat.decimalPattern('id_ID');

// Leaves headroom for SQLite SUM calculations while remaining far above any
// realistic personal IDR transaction.
const int maxMoneyAmount = 9000000000000000;

String formatRupiah(int amount) => 'Rp ${_idr.format(amount)}';

int parseRupiah(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number = int.tryParse(digits);
    if (number == null) return oldValue;
    final formatted = _idr.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
