import 'package:ferikmoney/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats and parses Indonesian Rupiah without decimals', () {
    expect(formatRupiah(5300000), 'Rp 5.300.000');
    expect(parseRupiah('Rp 1.500.000'), 1500000);
    expect(parseRupiah(''), 0);
  });
}
