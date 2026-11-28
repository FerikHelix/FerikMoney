import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/activity_tile.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(databaseProvider)
        .transactionDao
        .watchRecentActivity(limit: 500);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.transactionHistory),
        actions: [
          IconButton(
            onPressed: () => context.push('/transactions/categories'),
            icon: const Icon(Symbols.category_rounded),
            tooltip: context.l10n.categoryManagement,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-history',
        onPressed: () => context.push('/transactions/new?type=expense'),
        tooltip: context.l10n.addTransaction,
        child: const Icon(Symbols.add_rounded),
      ),
      body: StreamBuilder<List<ActivityItem>>(
        stream: stream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ActivityItem>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return EmptyState(
              icon: Symbols.receipt_long_rounded,
              title: context.l10n.emptyTransactionsBody,
              body: context.l10n.emptyHistoryBody,
              actionLabel: context.l10n.addTransaction,
              onAction: () => context.push('/transactions/new?type=expense'),
            );
          }
          String? currentDate;
          final children = <Widget>[];
          for (final item in items) {
            if (item.date != currentDate) {
              currentDate = item.date;
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  child: Text(
                    formatDateLabel(context, item.date),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            children.add(
              ActivityTile(
                item: item,
                onTap: () {
                  final type = item.isTransfer
                      ? 'transfer'
                      : item.kind == ActivityKind.income
                      ? 'income'
                      : 'expense';
                  context.push('/transactions/${item.id}/edit?type=$type');
                },
                onDelete: () => _delete(context, ref, item),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: children,
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ActivityItem item,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.deleteTransaction,
      body: context.l10n.deleteTransactionBody,
      confirmLabel: context.l10n.delete,
    );
    if (!confirmed) {
      return;
    }
    final dao = ref.read(databaseProvider).transactionDao;
    if (item.isTransfer) {
      await dao.deleteTransfer(item.id);
    } else {
      await dao.deleteTransaction(item.id);
    }
    if (context.mounted) {
      showSavedMessage(context, context.l10n.transactionDeleted);
    }
  }
}
