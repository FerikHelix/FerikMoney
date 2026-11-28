import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/dates/date_keys.dart';
import '../../core/dates/subscription_due.dart';
import '../../core/db/database.dart';
import '../../core/money/rupiah.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/l10n.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final wallets = ref.watch(allWalletBalancesProvider).value ?? const [];
    final walletNames = {
      for (final item in wallets) item.wallet.id: item.wallet.name,
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.subscriptionsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-subscriptions',
        onPressed: () => context.push('/subscriptions/new'),
        tooltip: context.l10n.newSubscription,
        child: const Icon(Symbols.add_rounded),
      ),
      body: subscriptions.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Symbols.event_repeat_rounded,
              title: context.l10n.subscriptionsTitle,
              body: context.l10n.noSubscriptionsBody,
              actionLabel: context.l10n.newSubscription,
              onAction: () => context.push('/subscriptions/new'),
            );
          }
          final active = items.where((s) => s.active).toList();
          final inactive = items.where((s) => !s.active).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final subscription in active)
                _SubscriptionCard(
                  subscription: subscription,
                  walletName: walletNames[subscription.walletId],
                  onEdit: () =>
                      context.push('/subscriptions/${subscription.id}/edit'),
                  onPay: () => _pay(context, subscription),
                  onSkip: () => _skip(context, ref, subscription),
                  onDeactivate: () =>
                      _toggle(context, ref, subscription, false),
                ),
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.inactiveLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                for (final subscription in inactive)
                  _SubscriptionCard(
                    subscription: subscription,
                    walletName: walletNames[subscription.walletId],
                    onEdit: () =>
                        context.push('/subscriptions/${subscription.id}/edit'),
                    onPay: () => _pay(context, subscription),
                    onSkip: () => _skip(context, ref, subscription),
                    onDeactivate: () =>
                        _toggle(context, ref, subscription, true),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(context.l10n.loadFailed)),
      ),
    );
  }

  void _pay(BuildContext context, SubscriptionEntry subscription) {
    context.push(
      '/transactions/new?type=expense&subscriptionId=${subscription.id}'
      '&amount=${subscription.amount}'
      '&walletId=${subscription.walletId}'
      '&categoryId=${subscription.categoryId}',
    );
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    SubscriptionEntry subscription,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: context.l10n.skipCycle,
      body: context.l10n.skipCycleBody,
      confirmLabel: context.l10n.skip,
      destructive: false,
    );
    if (!confirmed) {
      return;
    }
    await ref
        .read(databaseProvider)
        .subscriptionDao
        .completeCycle(subscription.id);
    if (context.mounted) {
      showSavedMessage(context, context.l10n.subscriptionSkipped);
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    SubscriptionEntry subscription,
    bool active,
  ) async {
    await ref
        .read(databaseProvider)
        .subscriptionDao
        .setActive(subscription.id, active);
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.walletName,
    required this.onEdit,
    required this.onPay,
    required this.onSkip,
    required this.onDeactivate,
  });

  final SubscriptionEntry subscription;
  final String? walletName;
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onSkip;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDays = daysUntil(
      parseDateKey(subscription.nextDueDate),
      DateTime.now(),
    );
    final due = subscription.active && dueDays <= subscription.leadDays;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subscription.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (!subscription.active)
                        Chip(label: Text(context.l10n.inactiveLabel)),
                      if (due)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Chip(
                            backgroundColor: theme.colorScheme.errorContainer,
                            label: Text(
                              dueDays < 0
                                  ? context.l10n.overdue
                                  : context.l10n.dueSoon,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${subscription.cycle == 'monthly' ? context.l10n.monthly : context.l10n.yearly}'
                    '${walletName == null ? '' : ' · $walletName'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    context.l10n.nextDue(
                      formatDateLabel(context, subscription.nextDueDate),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(subscription.amount),
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit();
                  case 'pay':
                    onPay();
                  case 'skip':
                    onSkip();
                  case 'toggle':
                    onDeactivate();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'pay', child: Text(context.l10n.pay)),
                PopupMenuItem(
                  value: 'skip',
                  child: Text(context.l10n.skipCycle),
                ),
                PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    subscription.active
                        ? context.l10n.deactivate
                        : context.l10n.activate,
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
