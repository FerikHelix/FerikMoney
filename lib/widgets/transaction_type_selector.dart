import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.ferikColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _Segment(
            key: const Key('transaction-type-expense'),
            selected: value == 'expense',
            icon: Icons.arrow_downward_rounded,
            label: 'Keluar',
            color: colors.expense,
            selectedBackground: colors.expenseSoft,
            onTap: () => onChanged('expense'),
          ),
          _Segment(
            key: const Key('transaction-type-income'),
            selected: value == 'income',
            icon: Icons.arrow_upward_rounded,
            label: 'Masuk',
            color: colors.income,
            selectedBackground: colors.incomeSoft,
            onTap: () => onChanged('income'),
          ),
          _Segment(
            key: const Key('transaction-type-transfer'),
            selected: value == 'transfer',
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            color: colors.transfer,
            selectedBackground: colors.transferSoft,
            onTap: () => onChanged('transfer'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.color,
    required this.selectedBackground,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color color;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: selected
                    ? context.ferikTint(color, selectedBackground)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: selected
                    ? Border.all(color: color.withValues(alpha: 0.32))
                    : null,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: selected
                          ? color
                          : context.ferikColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? color
                            : context.ferikColors.secondaryText,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
