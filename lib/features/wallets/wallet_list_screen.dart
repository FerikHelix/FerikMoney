import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/models/models.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/display.dart';
import '../../core/widgets/l10n.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(allWalletBalancesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.walletsTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Symbols.settings_rounded),
            tooltip: context.l10n.settings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-wallets',
        onPressed: () => context.push('/wallets/new'),
        tooltip: context.l10n.newWallet,
        child: const Icon(Symbols.add_rounded),
      ),
      body: balances.when(
        data: (items) {
          final active = items
              .where((w) => w.wallet.archivedAt == null)
              .toList();
          final archived = items
              .where((w) => w.wallet.archivedAt != null)
              .toList();
          if (items.isEmpty) {
            return EmptyState(
              icon: Symbols.account_balance_wallet_rounded,
              title: context.l10n.walletsTitle,
              body: context.l10n.noWalletsBody,
              actionLabel: context.l10n.createWallet,
              onAction: () => context.push('/wallets/new'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (active.isNotEmpty) ...[
                _SectionLabel(label: context.l10n.activeWallets),
                for (final item in active)
                  _WalletCard(
                    item: item,
                    onTap: () {
                      context.push('/wallets/${item.wallet.id}');
                    },
                  ),
              ],
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionLabel(label: context.l10n.archivedWallets),
                for (final item in archived)
                  _WalletCard(
                    item: item,
                    archived: true,
                    onTap: () {
                      context.push('/wallets/${item.wallet.id}');
                    },
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: EmptyState(
            icon: Symbols.error_rounded,
            title: context.l10n.loadFailed,
            body: '',
            actionLabel: context.l10n.retry,
            onAction: () => ref.invalidate(allWalletBalancesProvider),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.item,
    required this.onTap,
    this.archived = false,
  });

  final WalletBalance item;
  final VoidCallback onTap;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = item.wallet;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: WalletAvatar(
          iconCodePoint: wallet.iconCodePoint,
          colorValue: wallet.colorValue,
        ),
        title: Text(wallet.name),
        subtitle: Text(
          [
            walletTypeLabel(context, WalletType.parse(wallet.type)),
            if (archived) context.l10n.archivedWallets,
          ].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BalanceText(
              amount: item.balance,
              style: theme.textTheme.titleSmall,
            ),
            if (item.isNegative)
              Text(
                context.l10n.negativeBalance,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
