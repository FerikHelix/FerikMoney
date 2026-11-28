import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../core/widgets/l10n.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.home_rounded),
            selectedIcon: const Icon(Symbols.home_rounded),
            label: context.l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.account_balance_wallet_rounded),
            selectedIcon: const Icon(Symbols.account_balance_wallet_rounded),
            label: context.l10n.navWallets,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.bar_chart_rounded),
            selectedIcon: const Icon(Symbols.bar_chart_rounded),
            label: context.l10n.navAnalytics,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.event_repeat_rounded),
            selectedIcon: const Icon(Symbols.event_repeat_rounded),
            label: context.l10n.navSubscriptions,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.handshake_rounded),
            selectedIcon: const Icon(Symbols.handshake_rounded),
            label: context.l10n.navDebts,
          ),
        ],
      ),
    );
  }
}
