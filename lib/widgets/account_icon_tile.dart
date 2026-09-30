import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../utils/icon_mapper.dart';

/// Accent color for an account type, tuned separately for light and dark.
Color accountTypeColor(BuildContext context, String type) {
  final colors = context.ferikColors;
  final dark = context.isFerikDark;
  return switch (type) {
    'bank' => colors.transfer,
    'ewallet' => dark ? const Color(0xFFB9A1FF) : const Color(0xFF8B72BE),
    'savings' => dark ? const Color(0xFFF3B96C) : const Color(0xFFD49A3A),
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
        color: color.withValues(alpha: context.isFerikDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(accountTypeIcon(type), size: size * 0.52, color: color),
    );
  }
}
