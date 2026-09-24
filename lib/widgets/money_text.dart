import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../utils/money_formatter.dart';

enum MoneyTone { neutral, income, expense, transfer }

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.amount,
    this.visible = true,
    this.tone = MoneyTone.neutral,
    this.showSign = false,
    this.style,
    this.textAlign,
    this.scaleDown = false,
  });

  final int amount;
  final bool visible;
  final MoneyTone tone;
  final bool showSign;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    final color = switch (tone) {
      MoneyTone.income => colors.income,
      MoneyTone.expense => colors.expense,
      MoneyTone.transfer => colors.transfer,
      MoneyTone.neutral => style?.color ?? colors.mainText,
    };
    final value = visible ? _formattedValue() : 'Rp •••••••';
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

  String _formattedValue() {
    final absolute = amount.abs();
    final value = formatRupiah(absolute);
    if (amount < 0) return '−$value';
    if (!showSign) return value;
    return switch (tone) {
      MoneyTone.income => '+$value',
      MoneyTone.expense => '−$value',
      _ => value,
    };
  }
}
