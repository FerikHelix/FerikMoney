import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../models/models.dart';
import '../money/rupiah.dart';
import 'l10n.dart';

IconData walletTypeIcon(WalletType type) => switch (type) {
  WalletType.cash => Symbols.payments_rounded,
  WalletType.bank => Symbols.account_balance_rounded,
  WalletType.ewallet => Symbols.smartphone_rounded,
  WalletType.other => Symbols.account_balance_wallet_rounded,
};

String walletTypeLabel(BuildContext context, WalletType type) => switch (type) {
  WalletType.cash => context.l10n.typeCash,
  WalletType.bank => context.l10n.typeBank,
  WalletType.ewallet => context.l10n.typeEwallet,
  WalletType.other => context.l10n.typeOther,
};

class WalletAvatar extends StatelessWidget {
  const WalletAvatar({
    required this.iconCodePoint,
    required this.colorValue,
    this.size = 40,
    super.key,
  });

  final int iconCodePoint;
  final int colorValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(symbolIcon(iconCodePoint), color: color, size: size * 0.55),
    );
  }
}

class BalanceText extends StatelessWidget {
  const BalanceText({
    required this.amount,
    this.style,
    this.showSign = false,
    super.key,
  });

  final int amount;
  final TextStyle? style;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = amount < 0 ? theme.colorScheme.error : null;
    final text = showSign && amount > 0
        ? '+${formatRupiah(amount)}'
        : formatRupiah(amount);
    return Text(
      text,
      style: (style ?? theme.textTheme.titleMedium)?.copyWith(color: color),
      semanticsLabel: formatRupiah(amount),
    );
  }
}

IconData symbolIcon(int codePoint) {
  if (codePoint == Symbols.payments_rounded.codePoint) {
    return Symbols.payments_rounded;
  }
  if (codePoint == Symbols.account_balance_rounded.codePoint) {
    return Symbols.account_balance_rounded;
  }
  if (codePoint == Symbols.account_balance_wallet_rounded.codePoint) {
    return Symbols.account_balance_wallet_rounded;
  }
  if (codePoint == Symbols.savings_rounded.codePoint) {
    return Symbols.savings_rounded;
  }
  if (codePoint == Symbols.credit_card_rounded.codePoint) {
    return Symbols.credit_card_rounded;
  }
  if (codePoint == Symbols.smartphone_rounded.codePoint) {
    return Symbols.smartphone_rounded;
  }
  if (codePoint == Symbols.storefront_rounded.codePoint) {
    return Symbols.storefront_rounded;
  }
  if (codePoint == Symbols.business_center_rounded.codePoint) {
    return Symbols.business_center_rounded;
  }
  if (codePoint == Symbols.home_rounded.codePoint) {
    return Symbols.home_rounded;
  }
  if (codePoint == Symbols.favorite_rounded.codePoint) {
    return Symbols.favorite_rounded;
  }
  if (codePoint == Symbols.restaurant_rounded.codePoint) {
    return Symbols.restaurant_rounded;
  }
  if (codePoint == Symbols.directions_bus_rounded.codePoint) {
    return Symbols.directions_bus_rounded;
  }
  if (codePoint == Symbols.shopping_bag_rounded.codePoint) {
    return Symbols.shopping_bag_rounded;
  }
  if (codePoint == Symbols.receipt_long_rounded.codePoint) {
    return Symbols.receipt_long_rounded;
  }
  if (codePoint == Symbols.movie_rounded.codePoint) {
    return Symbols.movie_rounded;
  }
  if (codePoint == Symbols.medical_services_rounded.codePoint) {
    return Symbols.medical_services_rounded;
  }
  if (codePoint == Symbols.school_rounded.codePoint) {
    return Symbols.school_rounded;
  }
  if (codePoint == Symbols.work_rounded.codePoint) {
    return Symbols.work_rounded;
  }
  if (codePoint == Symbols.redeem_rounded.codePoint) {
    return Symbols.redeem_rounded;
  }
  if (codePoint == Symbols.trending_up_rounded.codePoint) {
    return Symbols.trending_up_rounded;
  }
  if (codePoint == Symbols.swap_horiz_rounded.codePoint) {
    return Symbols.swap_horiz_rounded;
  }
  return Symbols.category_rounded;
}
