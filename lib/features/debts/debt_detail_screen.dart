import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/models/models.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';
import 'commit_picker.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({required this.debtId, super.key});

  final int debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(debtStatusProvider(debtId));
    if (status == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.debtsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final entry = status.entry;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(status.isUtang ? context.l10n.utang : context.l10n.piutang),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) async {
              switch (action) {
                case 'payment':
                  await context.push('/debts/$debtId/payment');
                case 'commit':
                  await _commit(context, ref, status);
                case 'delete':
                  await _delete(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'payment',
                child: Text(context.l10n.recordPayment),
              ),
              if (!status.isCommitted)
                PopupMenuItem(
                  value: 'commit',
                  child: Text(context.l10n.commitToMoney),
                ),
              PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.counterparty,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Chip(
                        label: Text(
                          status.isSettled
                              ? context.l10n.settled
                              : status.isOverdue
                              ? context.l10n.overdue
                              : context.l10n.openStatus,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AmountRow(
                    label: context.l10n.principal,
                    amount: entry.principal,
                  ),
                  _AmountRow(
                    label: context.l10n.paymentsTitle,
                    amount: status.paid,
                  ),
                  const Divider(),
                  _AmountRow(
                    label: context.l10n.remaining,
                    amount: status.remaining,
                    emphasize: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${context.l10n.startDate}: ${formatDateLabel(context, entry.startDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.dueDate != null)
                    Text(
                      '${context.l10n.dueDate}: ${formatDateLabel(context, entry.dueDate!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(entry.note),
                  ],
                  if (status.isCommitted) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Symbols.check_circle_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(context.l10n.committedLabel),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.paymentsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (status.payments.isEmpty)
            EmptyState(
              icon: Symbols.payments_rounded,
              title: context.l10n.noPaymentsBody,
              body: '',
              actionLabel: context.l10n.recordPayment,
              onAction: () => context.push('/debts/$debtId/payment'),
            )
          else
            for (final payment in status.payments)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Symbols.payments_rounded),
                  title: Text(formatRupiah(payment.amount)),
                  subtitle: Text(
                    [
                      formatDateLabel(context, payment.date),
                      if (payment.note.isNotEmpty) payment.note,
                    ].join(' · '),
                  ),
                  trailing: payment.transactionId == null
                      ? null
                      : const Icon(Symbols.check_circle_rounded),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-debt-$debtId',
        onPressed: () => context.push('/debts/$debtId/payment'),
        tooltip: context.l10n.recordPayment,
        child: const Icon(Symbols.add_rounded),
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    DebtStatus status,
  ) async {
    final kind = status.isUtang ? CategoryKind.income : CategoryKind.expense;
    final selection = await showCommitPicker(context, kind: kind);
    if (selection == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(databaseProvider)
          .debtDao
          .commitPrincipal(
            debtId: debtId,
            walletId: selection.walletId,
            categoryId: selection.categoryId,
          );
      if (context.mounted) {
        showSavedMessage(context, context.l10n.committedLabel);
      }
    } catch (error) {
      if (context.mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.deleteDebt,
      body: context.l10n.deleteDebtBody,
      confirmLabel: context.l10n.delete,
    );
    if (!confirmed) {
      return;
    }
    await ref.read(databaseProvider).debtDao.deleteEntry(debtId);
    if (context.mounted) {
      showSavedMessage(context, context.l10n.debtDeleted);
      context.pop();
    }
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final int amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(formatRupiah(amount), style: style),
        ],
      ),
    );
  }
}
