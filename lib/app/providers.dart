import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/db/daos/settings_dao.dart';
import '../core/db/database.dart';
import '../core/models/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final themeModeProvider = StreamProvider<ThemeMode>((ref) {
  final database = ref.watch(databaseProvider);
  return database.settingsDao
      .watchValue(SettingsDao.themeModeKey)
      .map(ThemeModeController.parse);
});

class ThemeModeController {
  const ThemeModeController(this.ref);

  final Ref ref;

  static ThemeMode parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  Future<void> setMode(ThemeMode mode) async {
    await ref
        .read(databaseProvider)
        .settingsDao
        .setValue(SettingsDao.themeModeKey, encode(mode));
  }
}

final themeModeControllerProvider = Provider<ThemeModeController>(
  ThemeModeController.new,
);

final activeWalletBalancesProvider = StreamProvider<List<WalletBalance>>((ref) {
  return ref.watch(databaseProvider).walletDao.watchBalances();
});

final allWalletBalancesProvider = StreamProvider<List<WalletBalance>>((ref) {
  return ref.watch(databaseProvider).walletDao.watchBalances(activeOnly: false);
});

final activeWalletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(databaseProvider).walletDao.active().asStream();
});

final walletProvider = StreamProvider.family<Wallet?, int>((ref, id) {
  return ref.watch(databaseProvider).walletDao.watchById(id);
});

final categoriesProvider = StreamProvider.family<List<Category>, CategoryKind>((
  ref,
  kind,
) {
  return ref.watch(databaseProvider).transactionDao.watchCategories(kind: kind);
});

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref
      .watch(databaseProvider)
      .transactionDao
      .watchCategories(activeOnly: false);
});

final recentActivityProvider = StreamProvider<List<ActivityItem>>((ref) {
  return ref.watch(databaseProvider).transactionDao.watchRecentActivity();
});

final monthSnapshotProvider =
    StreamProvider.family<AnalyticsSnapshot, ({DateTime month, int? walletId})>(
      (ref, args) {
        return ref
            .watch(databaseProvider)
            .analyticsDao
            .watchSnapshot(month: args.month, walletId: args.walletId);
      },
    );

final subscriptionsProvider = StreamProvider<List<SubscriptionEntry>>((ref) {
  return ref.watch(databaseProvider).subscriptionDao.watchAll();
});

final dueSubscriptionsProvider = StreamProvider<List<SubscriptionEntry>>((ref) {
  return ref.watch(databaseProvider).subscriptionDao.watchDue(DateTime.now());
});

final dismissedSubscriptionsProvider =
    NotifierProvider<DismissedSubscriptions, Set<int>>(
      DismissedSubscriptions.new,
    );

class DismissedSubscriptions extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  void dismiss(int id) {
    state = {...state, id};
  }
}

final debtStatusesProvider = StreamProvider<List<DebtStatus>>((ref) {
  return ref.watch(databaseProvider).debtDao.watchStatuses();
});

final debtSummaryProvider = Provider<DebtSummary>((ref) {
  final statuses =
      ref.watch(debtStatusesProvider).value ?? const <DebtStatus>[];
  var utang = 0;
  var piutang = 0;
  for (final status in statuses) {
    if (status.remaining <= 0) {
      continue;
    }
    if (status.isUtang) {
      utang += status.remaining;
    } else {
      piutang += status.remaining;
    }
  }
  return DebtSummary(totalUtang: utang, totalPiutang: piutang);
});

final debtStatusProvider = Provider.family<DebtStatus?, int>((ref, id) {
  final statuses =
      ref.watch(debtStatusesProvider).value ?? const <DebtStatus>[];
  for (final status in statuses) {
    if (status.entry.id == id) {
      return status;
    }
  }
  return null;
});
