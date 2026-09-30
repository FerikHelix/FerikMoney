import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';
import '../database/app_database.dart';
import '../utils/icon_mapper.dart';
import 'money_text.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.accountName,
    this.destinationName,
    this.category,
    this.dateLabel,
    this.onTap,
    this.showDivider = false,
    this.visible = true,
  });

  final MoneyTransaction transaction;
  final String accountName;
  final String? destinationName;
  final Category? category;
  final String? dateLabel;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    final tone = switch (transaction.type) {
      'income' => MoneyTone.income,
      'expense' => MoneyTone.expense,
      _ => MoneyTone.transfer,
    };
    final semanticColor = switch (tone) {
      MoneyTone.income => colors.income,
      MoneyTone.expense => colors.expense,
      MoneyTone.transfer => colors.transfer,
      MoneyTone.neutral => colors.mainText,
    };
    final semanticBackground = context.ferikTint(semanticColor, switch (tone) {
      MoneyTone.income => colors.incomeSoft,
      MoneyTone.expense => colors.expenseSoft,
      MoneyTone.transfer => colors.transferSoft,
      MoneyTone.neutral => colors.surfaceVariant,
    }, darkAlpha: 0.12);
    final hasNote = transaction.note?.trim().isNotEmpty == true;
    final title = hasNote
        ? transaction.note!.trim()
        : transaction.type == 'transfer'
        ? 'Transfer'
        : category?.name ?? 'Transaksi';
    final metadata = transaction.type == 'transfer'
        ? '$accountName \u2192 ${destinationName ?? '-'}'
        : [
            hasNote ? category?.name : null,
            accountName,
            dateLabel,
          ].whereType<String>().join(' \u2022 ');
    final icon = switch (transaction.type) {
      'income' => Icons.arrow_upward_rounded,
      'expense' => Icons.arrow_downward_rounded,
      _ => Icons.swap_horiz_rounded,
    };

    return Column(
      children: [
        Semantics(
          button: onTap != null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: semanticBackground,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        transaction.type == 'transfer'
                            ? icon
                            : iconForName(category?.icon ?? 'label'),
                        size: 21,
                        color: semanticColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width:
                          MediaQuery.sizeOf(context).width.clamp(320, 480) *
                          0.29,
                      child: MoneyText(
                        amount: transaction.amount,
                        visible: visible,
                        tone: tone,
                        showSign: transaction.type != 'transfer',
                        scaleDown: true,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(color: context.ferikHairline),
          ),
      ],
    );
  }
}
