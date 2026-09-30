import 'package:ferikmoney/services/app_preferences_service.dart';
import 'package:ferikmoney/services/currency_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'currency uses integer minor units and currency-specific decimals',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await AppPreferencesService().init();
      final currency = CurrencyService(preferences);

      expect(currency.formatInputDigits('12345'), '12.345');
      expect(currency.parseInput('Rp 12.345'), 12345);

      await preferences.setCurrency('USD');
      expect(currency.current.fractionDigits, 2);
      expect(currency.formatInputDigits('12345'), '123.45');
      expect(currency.parseInput(r'$ 123.45'), 12345);

      await preferences.setCurrency('JPY');
      expect(currency.current.fractionDigits, 0);
      expect(currency.formatInputDigits('12345'), '12,345');
    },
  );
}
