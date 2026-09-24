import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../utils/icon_mapper.dart';
import 'ferik_card.dart';
import 'money_text.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.name,
    required this.type,
    required this.iconName,
    required this.balance,
    required this.visible,
    required this.onTap,
    this.width,
  });

  final String name;
  final String type;
  final String iconName;
  final int balance;
  final bool visible;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return SizedBox(
      width: width,
      height: 132,
      child: FerikCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.isFerikDark
                        ? colors.primaryContainer
                        : colors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    iconForName(iconName),
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            MoneyText(
              amount: balance,
              visible: visible,
              scaleDown: true,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
