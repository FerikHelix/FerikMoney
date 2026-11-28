import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/widgets/l10n.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/debts/debt_detail_screen.dart';
import '../features/debts/debt_form_screen.dart';
import '../features/debts/debt_payment_screen.dart';
import '../features/debts/debts_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/subscriptions/subscription_form_screen.dart';
import '../features/subscriptions/subscriptions_screen.dart';
import '../features/transactions/category_management_screen.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/transaction_history_screen.dart';
import '../features/wallets/wallet_detail_screen.dart';
import '../features/wallets/wallet_form_screen.dart';
import '../features/wallets/wallet_list_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallets',
                builder: (context, state) => const WalletListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscriptions',
                builder: (context, state) => const SubscriptionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/debts',
                builder: (context, state) => const DebtsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/wallets/new',
        builder: (context, state) => const WalletFormScreen(),
      ),
      GoRoute(
        path: '/wallets/:id/edit',
        builder: (context, state) => WalletFormScreen(
          walletId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/wallets/:id',
        builder: (context, state) => WalletDetailScreen(
          walletId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return TransactionFormScreen(
            type: _transactionType(query['type']),
            subscriptionId: int.tryParse(query['subscriptionId'] ?? ''),
            prefillAmount: int.tryParse(query['amount'] ?? ''),
            prefillWalletId: int.tryParse(query['walletId'] ?? ''),
            prefillCategoryId: int.tryParse(query['categoryId'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/transactions/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return TransactionFormScreen(
            type: _transactionType(query['type']),
            transactionId: int.tryParse(state.pathParameters['id'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/subscriptions/new',
        builder: (context, state) => const SubscriptionFormScreen(),
      ),
      GoRoute(
        path: '/subscriptions/:id/edit',
        builder: (context, state) => SubscriptionFormScreen(
          subscriptionId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/debts/new',
        builder: (context, state) {
          final direction = state.uri.queryParameters['direction'] == 'piutang'
              ? 'piutang'
              : 'utang';
          return DebtFormScreen(direction: direction);
        },
      ),
      GoRoute(
        path: '/debts/:id/payment',
        builder: (context, state) => DebtPaymentScreen(
          debtId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/debts/:id',
        builder: (context, state) => DebtDetailScreen(
          debtId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(context.l10n.notFound)),
    ),
  );
});

TransactionFormType _transactionType(String? value) => switch (value) {
  'income' => TransactionFormType.income,
  'transfer' => TransactionFormType.transfer,
  _ => TransactionFormType.expense,
};
