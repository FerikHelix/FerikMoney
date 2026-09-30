import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/theme/design_tokens.dart';
import '../models/finance_models.dart';
import '../features/main/money_controller.dart';
import '../features/savings/savings_controller.dart';
import 'money_text.dart';
import 'transaction_tile.dart';

class FinanceActivityTile extends StatelessWidget {
  const FinanceActivityTile({
    super.key,
    required this.activity,
    required this.visible,
    this.showDivider = false,
    this.onTransactionTap,
  });

  final FinanceActivity activity;
  final bool visible;
  final bool showDivider;
  final VoidCallback? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final transaction = activity.transaction;
    if (transaction != null) {
      final money = Get.find<MoneyController>();
      return TransactionTile(
        transaction: transaction.transaction,
        accountName:
            money
                .accountById(transaction.transaction.accountId)
                ?.account
                .name ??
            '-',
        destinationName: money
            .accountById(transaction.transaction.destinationAccountId)
            ?.account
            .name,
        category: money.categoryById(transaction.transaction.categoryId),
        visible: visible,
        showDivider: showDivider,
        onTap: onTransactionTap,
      );
    }
    final transfer = activity.goalTransfer!;
    final money = Get.find<MoneyController>();
    final savings = Get.find<SavingsController>();
    final account = money.accountById(transfer.accountId)?.account.name ?? '-';
    final goal = savings.goalById(transfer.goalId)?.goal.name ?? 'Target';
    final deposit = transfer.type == 'deposit';
    return Column(
      children: [
        Padding(
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
                  color: context.ferikColors.transferSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  deposit ? Icons.savings_outlined : Icons.wallet_outlined,
                  color: context.ferikColors.transfer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit ? 'Transfer ke $goal' : 'Penarikan dari $goal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(account, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: MediaQuery.sizeOf(context).width.clamp(320, 480) * 0.29,
                child: MoneyText(
                  amount: transfer.amount,
                  visible: visible,
                  tone: MoneyTone.transfer,
                  scaleDown: true,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(padding: EdgeInsets.only(left: 66), child: Divider()),
      ],
    );
  }
}
