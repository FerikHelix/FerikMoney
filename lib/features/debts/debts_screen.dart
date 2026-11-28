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

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(debtStatusesProvider);
    final summary = ref.watch(debtSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.debtsTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/debts/new?direction=piutang'),
            icon: const Icon(Symbols.request_quote_rounded),
            tooltip: context.l10n.newReceivable,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-debts',
        onPressed: () => context.push('/debts/new?direction=utang'),
        tooltip: context.l10n.newDebt,
        child: const Icon(Symbols.add_rounded),
      ),
      body: statuses.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Symbols.handshake_rounded,
              title: context.l10n.debtsTitle,
              body: context.l10n.noDebtsBody,
              actionLabel: context.l10n.newDebt,
              onAction: () => context.push('/debts/new?direction=utang'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.totalUtang,
                      amount: summary.totalUtang,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.totalPiutang,
                      amount: summary.totalPiutang,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final status in items) _DebtCard(status: status),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(context.l10n.loadFailed)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              formatRupiah(amount),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.status});

  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = status.entry;
    final statusLabel = status.isSettled
        ? context.l10n.settled
        : status.isOverdue
        ? context.l10n.overdue
        : context.l10n.openStatus;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/debts/${entry.id}'),
        leading: CircleAvatar(
          backgroundColor: status.isUtang
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            status.isUtang
                ? Symbols.arrow_upward_rounded
                : Symbols.arrow_downward_rounded,
            color: status.isUtang
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(entry.counterparty),
        subtitle: Text(
          '${status.isUtang ? context.l10n.utang : context.l10n.piutang}'
          ' · ${formatDateLabel(context, entry.startDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRupiah(status.remaining),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: status.isOverdue
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
