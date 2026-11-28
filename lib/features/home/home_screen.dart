import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/dates/date_keys.dart';
import '../../core/db/database.dart';
import '../../core/models/models.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/activity_tile.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/display.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';
import '../wallets/wallet_editor.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _skippedWelcome = false;

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(activeWalletBalancesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appName),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Symbols.settings_rounded),
            tooltip: context.l10n.settings,
          ),
        ],
      ),
      floatingActionButton: (wallets.value?.isNotEmpty ?? false)
          ? FloatingActionButton(
              heroTag: 'fab-home',
              onPressed: () => context.push('/transactions/new?type=expense'),
              tooltip: context.l10n.addExpense,
              child: const Icon(Symbols.add_rounded),
            )
          : null,
      body: wallets.when(
        data: (items) {
          if (items.isEmpty && !_skippedWelcome) {
            return _FirstRunView(
              onSkip: () => setState(() => _skippedWelcome = true),
            );
          }
          return _Dashboard(wallets: items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: EmptyState(
            icon: Symbols.error_rounded,
            title: context.l10n.loadFailed,
            body: '',
            actionLabel: context.l10n.retry,
            onAction: () => ref.invalidate(activeWalletBalancesProvider),
          ),
        ),
      ),
    );
  }
}

class _FirstRunView extends ConsumerStatefulWidget {
  const _FirstRunView({required this.onSkip});

  final VoidCallback onSkip;

  @override
  ConsumerState<_FirstRunView> createState() => _FirstRunViewState();
}

class _FirstRunViewState extends ConsumerState<_FirstRunView> {
  final _editorKey = GlobalKey<WalletEditorState>();
  bool _saving = false;

  Future<void> _save() async {
    final editor = _editorKey.currentState;
    if (editor == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (await editor.save() && mounted) {
        showSavedMessage(context, context.l10n.walletSaved);
      }
    } catch (error) {
      if (mounted) {
        showSavedMessage(context, errorMessage(context, error));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Symbols.account_balance_wallet_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.firstWalletTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(context.l10n.firstWalletBody),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: WalletEditor(key: _editorKey)),
        SaveBar(
          label: context.l10n.createWallet,
          onPressed: _save,
          isSaving: _saving,
        ),
        TextButton(
          onPressed: widget.onSkip,
          child: Text(context.l10n.skipForNow),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.wallets});

  final List<WalletBalance> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = wallets.fold<int>(0, (sum, item) => sum + item.balance);
    final month = monthStart(DateTime.now());
    final snapshot = ref.watch(
      monthSnapshotProvider((month: month, walletId: null)),
    );
    final recent = ref.watch(recentActivityProvider);
    final due = ref.watch(dueSubscriptionsProvider);
    final dismissed = ref.watch(dismissedSubscriptionsProvider);
    final visibleDue = (due.value ?? const [])
        .where((item) => !dismissed.contains(item.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (visibleDue.isNotEmpty)
          _SubscriptionBanner(
            due: visibleDue,
            onDismiss: () {
              final notifier = ref.read(
                dismissedSubscriptionsProvider.notifier,
              );
              for (final item in visibleDue) {
                notifier.dismiss(item.id);
              }
            },
            onOpen: () => context.go('/subscriptions'),
          ),
        _TotalCard(
          total: total,
          summary: snapshot.value?.summary ?? MonthSummary.empty,
          month: month,
        ),
        const SizedBox(height: 12),
        _QuickActions(
          onExpense: () => context.push('/transactions/new?type=expense'),
          onIncome: () => context.push('/transactions/new?type=income'),
          onTransfer: () => context.push('/transactions/new?type=transfer'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.walletsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/wallets'),
              child: Text(context.l10n.seeAll),
            ),
          ],
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = wallets[index];
              return _WalletMiniCard(
                item: item,
                onTap: () => context.push('/wallets/${item.wallet.id}'),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.recentActivity,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(context.l10n.seeAll),
            ),
          ],
        ),
        recent.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Symbols.receipt_long_rounded,
                title: context.l10n.emptyTransactionsBody,
                body: context.l10n.emptyHistoryBody,
                actionLabel: context.l10n.addTransaction,
                onAction: () => context.push('/transactions/new?type=expense'),
              );
            }
            return Column(
              children: [
                for (final item in items.take(10))
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
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Text(context.l10n.loadFailed),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.summary,
    required this.month,
  });

  final int total;
  final MonthSummary summary;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.totalBalance,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  formatMonthLabel(month),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            BalanceText(amount: total, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: context.l10n.income,
                    amount: summary.income,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: context.l10n.expense,
                    amount: summary.expense,
                    color: theme.colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: context.l10n.net,
                    amount: summary.net,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          formatRupiah(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onExpense,
    required this.onIncome,
    required this.onTransfer,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onExpense,
          icon: const Icon(Symbols.remove_rounded),
          label: Text(context.l10n.addExpense),
        ),
        FilledButton.tonalIcon(
          onPressed: onIncome,
          icon: const Icon(Symbols.add_rounded),
          label: Text(context.l10n.addIncome),
        ),
        OutlinedButton.icon(
          onPressed: onTransfer,
          icon: const Icon(Symbols.swap_horiz_rounded),
          label: Text(context.l10n.addTransfer),
        ),
      ],
    );
  }
}

class _WalletMiniCard extends StatelessWidget {
  const _WalletMiniCard({required this.item, required this.onTap});

  final WalletBalance item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WalletAvatar(
                  iconCodePoint: item.wallet.iconCodePoint,
                  colorValue: item.wallet.colorValue,
                  size: 32,
                ),
                const Spacer(),
                Text(
                  item.wallet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  formatRupiah(item.balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: item.isNegative ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({
    required this.due,
    required this.onDismiss,
    required this.onOpen,
  });

  final List<SubscriptionEntry> due;
  final VoidCallback onDismiss;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nearest = due.first;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.notifications_active_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    due.length == 1
                        ? context.l10n.subscriptionDue
                        : context.l10n.subscriptionDueCount(due.length),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Symbols.close_rounded),
                  tooltip: context.l10n.dismiss,
                ),
              ],
            ),
            Text(
              '${nearest.name} · ${formatRupiah(nearest.amount)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpen,
                child: Text(context.l10n.seeAll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
