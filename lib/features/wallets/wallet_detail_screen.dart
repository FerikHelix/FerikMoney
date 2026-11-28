import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/db/errors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/activity_tile.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/display.dart';
import '../../core/widgets/l10n.dart';

class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({required this.walletId, super.key});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider(walletId));
    final balances = ref.watch(allWalletBalancesProvider);
    return wallet.when(
      data: (value) {
        if (value == null) {
          return Scaffold(body: Center(child: Text(context.l10n.loadFailed)));
        }
        final balance = balances.value
            ?.where((item) => item.wallet.id == walletId)
            .firstOrNull;
        final archived = value.archivedAt != null;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.walletDetail),
            actions: [
              PopupMenuButton<String>(
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      await context.push('/wallets/$walletId/edit');
                    case 'archive':
                      await _archive(context, ref);
                    case 'delete':
                      await _delete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Symbols.edit_rounded),
                      title: Text(context.l10n.edit),
                    ),
                  ),
                  if (!archived)
                    PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                        leading: const Icon(Symbols.archive_rounded),
                        title: Text(context.l10n.archive),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Symbols.delete_rounded),
                      title: Text(context.l10n.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<ActivityItem>>(
            stream: ref
                .watch(databaseProvider)
                .transactionDao
                .watchRecentActivity(limit: 100, walletId: walletId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ActivityItem>[];
              return ListView(
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
                              WalletAvatar(
                                iconCodePoint: value.iconCodePoint,
                                colorValue: value.colorValue,
                                size: 48,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      value.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      walletTypeLabel(
                                        context,
                                        WalletType.parse(value.type),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (archived)
                                Chip(label: Text(context.l10n.archivedWallets)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.totalBalance,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          BalanceText(
                            amount: balance?.balance ?? value.openingBalance,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if ((balance?.balance ?? 0) < 0)
                            Text(
                              context.l10n.negativeBalance,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.recentActivity,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    EmptyState(
                      icon: Symbols.receipt_long_rounded,
                      title: context.l10n.emptyTransactionsBody,
                      body: context.l10n.emptyHistoryBody,
                      actionLabel: context.l10n.addTransaction,
                      onAction: () =>
                          context.push('/transactions/new?type=expense'),
                    )
                  else
                    for (final item in items)
                      ActivityTile(
                        item: item,
                        onTap: () {
                          final type = item.isTransfer
                              ? 'transfer'
                              : item.kind == ActivityKind.income
                              ? 'income'
                              : 'expense';
                          context.push(
                            '/transactions/${item.id}/edit?type=$type',
                          );
                        },
                      ),
                ],
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text(context.l10n.loadFailed))),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.archiveWallet,
      body: context.l10n.archiveWalletBody,
      confirmLabel: context.l10n.archive,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(databaseProvider).walletDao.archiveWallet(walletId);
      if (context.mounted) {
        showSavedMessage(context, context.l10n.walletArchived);
        context.pop();
      }
    } on DomainError catch (error) {
      if (context.mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.deleteWallet,
      body: context.l10n.deleteWalletBody,
      confirmLabel: context.l10n.delete,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(databaseProvider).walletDao.deleteWallet(walletId);
      if (context.mounted) {
        showSavedMessage(context, context.l10n.walletDeleted);
        context.pop();
      }
    } on DomainError catch (error) {
      if (context.mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    }
  }
}
