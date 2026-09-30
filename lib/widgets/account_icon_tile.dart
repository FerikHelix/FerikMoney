import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../utils/icon_mapper.dart';

/// Accent color for an account type, tuned separately for light and dark.
Color accountTypeColor(BuildContext context, String type) {
  final colors = context.ferikColors;
  return switch (type) {
    'bank' => colors.transfer,
    'ewallet' => context.ferikViolet,
    'savings' => colors.warning,
    'other' => colors.secondaryText,
    _ => colors.income,
  };
}

/// Rounded, tinted icon tile that identifies an account by its type.
class AccountIconTile extends StatelessWidget {
  const AccountIconTile({super.key, required this.type, this.size = 40});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = accountTypeColor(context, type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.ferikWash(color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(accountTypeIcon(type), size: size * 0.52, color: color),
    );
  }
}
