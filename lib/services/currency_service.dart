import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'app_preferences_service.dart';

class CurrencyProfile {
  const CurrencyProfile({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.fractionDigits,
  });

  final String code;
  final String symbol;
  final String locale;
  final int fractionDigits;
}

class CurrencyService extends GetxService {
  CurrencyService(this.preferences);

  final AppPreferencesService preferences;

  static const supported = <CurrencyProfile>[
    CurrencyProfile(
      code: 'IDR',
      symbol: 'Rp',
      locale: 'id_ID',
      fractionDigits: 0,
    ),
    CurrencyProfile(
      code: 'USD',
      symbol: r'$',
      locale: 'en_US',
      fractionDigits: 2,
    ),
    CurrencyProfile(
      code: 'SGD',
      symbol: r'S$',
      locale: 'en_SG',
      fractionDigits: 2,
    ),
    CurrencyProfile(
      code: 'MYR',
      symbol: 'RM',
      locale: 'ms_MY',
      fractionDigits: 2,
    ),
    CurrencyProfile(
      code: 'THB',
      symbol: '฿',
      locale: 'th_TH',
      fractionDigits: 2,
    ),
    CurrencyProfile(
      code: 'JPY',
      symbol: '¥',
      locale: 'ja_JP',
      fractionDigits: 0,
    ),
  ];

  CurrencyProfile get current => profileFor(preferences.currencyCode.value);

  CurrencyProfile profileFor(String code) => supported.firstWhere(
    (item) => item.code == code,
    orElse: () => supported.first,
  );

  String format(int minorAmount, {bool includeCode = false}) {
    final profile = current;
    final divisor = math.pow(10, profile.fractionDigits);
    final value = minorAmount / divisor;
    final formatter = NumberFormat.currency(
      locale: profile.locale,
      symbol: '${profile.symbol} ',
      decimalDigits: profile.fractionDigits,
    );
    final formatted = formatter.format(value).trim();
    return includeCode ? '$formatted ${profile.code}' : formatted;
  }

  String formatInputDigits(String digits) {
    if (digits.isEmpty) return '';
    final amount = int.tryParse(digits) ?? 0;
    final profile = current;
    if (profile.fractionDigits == 0) {
      return NumberFormat.decimalPattern(profile.locale).format(amount);
    }
    final padded = digits.padLeft(profile.fractionDigits + 1, '0');
    final integerPart = padded.substring(
      0,
      padded.length - profile.fractionDigits,
    );
    final fractionPart = padded.substring(
      padded.length - profile.fractionDigits,
    );
    final integer = NumberFormat.decimalPattern(
      profile.locale,
    ).format(int.parse(integerPart));
    final separator = NumberFormat.decimalPattern(
      profile.locale,
    ).symbols.DECIMAL_SEP;
    return '$integer$separator$fractionPart';
  }

  int parseInput(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter(this.currency);

  final CurrencyService currency;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = currency.formatInputDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
