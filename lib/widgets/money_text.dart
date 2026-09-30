import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/theme/design_tokens.dart';
import '../services/currency_service.dart';
import '../services/privacy_service.dart';
import '../utils/money_formatter.dart';

enum MoneyTone { neutral, income, expense, transfer }

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.visible,
    this.tone = MoneyTone.neutral,
    this.showSign = false,
    this.style,
    this.textAlign,
    this.scaleDown = false,
  });

  final int amount;

  /// Null follows the app-wide "show amounts" setting, so a screen that forgets
  /// to pass it can never leak hidden numbers.
  final bool? visible;
  final MoneyTone tone;
  final bool showSign;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    final explicit = visible;
    if (explicit == null && Get.isRegistered<PrivacyService>()) {
      final privacy = Get.find<PrivacyService>();
      return Obx(() => _build(context, privacy.showMoney.value));
    }
    return _build(context, explicit ?? true);
  }

  Widget _build(BuildContext context, bool visible) {
    final colors = context.ferikColors;
    final color = switch (tone) {
      MoneyTone.income => colors.income,
      MoneyTone.expense => colors.expense,
      MoneyTone.transfer => colors.transfer,
      MoneyTone.neutral => style?.color ?? colors.mainText,
    };
    final currency = Get.isRegistered<CurrencyService>()
        ? Get.find<CurrencyService>()
        : null;
    final value = visible
        ? _formattedValue(currency)
        : '${currency?.current.symbol ?? 'Rp'} •••••••';
    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.visible,
      textAlign: textAlign,
      style:
          style?.copyWith(color: color) ??
          Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
    return Semantics(
      label: visible ? value : 'Nominal disembunyikan',
      excludeSemantics: true,
      child: scaleDown
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: textAlign == TextAlign.end
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: text,
            )
          : text,
    );
  }

  String _formattedValue(CurrencyService? currency) {
    final absolute = amount.abs();
    final value = currency?.format(absolute) ?? formatRupiah(absolute);
    if (amount < 0) return '−$value';
    if (!showSign) return value;
    return switch (tone) {
      MoneyTone.income => '+$value',
      MoneyTone.expense => '−$value',
      _ => value,
    };
  }
}
