import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart' hide Table;
import 'package:material_symbols_icons/symbols.dart';

import '../models/models.dart';
import 'daos/analytics_dao.dart';
import 'daos/debt_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/subscription_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/wallet_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Transfers,
    Subscriptions,
    DebtEntries,
    DebtPayments,
    Settings,
  ],
  daos: [
    WalletDao,
    TransactionDao,
    AnalyticsDao,
    SubscriptionDao,
    DebtDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'ferik_money'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedCategories() async {
    final seeds = <_CategorySeed>[
      const _CategorySeed(
        name: 'Makan & Minum',
        kind: CategoryKind.expense,
        icon: Symbols.restaurant_rounded,
        color: 0xFFE07A5F,
      ),
      const _CategorySeed(
        name: 'Transportasi',
        kind: CategoryKind.expense,
        icon: Symbols.directions_bus_rounded,
        color: 0xFF457B9D,
      ),
      const _CategorySeed(
        name: 'Belanja',
        kind: CategoryKind.expense,
        icon: Symbols.shopping_bag_rounded,
        color: 0xFF9C6ADE,
      ),
      const _CategorySeed(
        name: 'Tagihan',
        kind: CategoryKind.expense,
        icon: Symbols.receipt_long_rounded,
        color: 0xFFE9A23B,
      ),
      const _CategorySeed(
        name: 'Hiburan',
        kind: CategoryKind.expense,
        icon: Symbols.movie_rounded,
        color: 0xFFD95D8A,
      ),
      const _CategorySeed(
        name: 'Kesehatan',
        kind: CategoryKind.expense,
        icon: Symbols.medical_services_rounded,
        color: 0xFF2A9D8F,
      ),
      const _CategorySeed(
        name: 'Pendidikan',
        kind: CategoryKind.expense,
        icon: Symbols.school_rounded,
        color: 0xFF3D7EDB,
      ),
      const _CategorySeed(
        name: 'Biaya Transfer',
        kind: CategoryKind.expense,
        icon: Symbols.swap_horiz_rounded,
        color: 0xFF607D8B,
        isSystem: true,
      ),
      const _CategorySeed(
        name: 'Lainnya',
        kind: CategoryKind.expense,
        icon: Symbols.category_rounded,
        color: 0xFF78909C,
      ),
      const _CategorySeed(
        name: 'Gaji',
        kind: CategoryKind.income,
        icon: Symbols.work_rounded,
        color: 0xFF2E7D32,
      ),
      const _CategorySeed(
        name: 'Bonus',
        kind: CategoryKind.income,
        icon: Symbols.redeem_rounded,
        color: 0xFF00897B,
      ),
      const _CategorySeed(
        name: 'Investasi',
        kind: CategoryKind.income,
        icon: Symbols.trending_up_rounded,
        color: 0xFF1565C0,
      ),
      const _CategorySeed(
        name: 'Lainnya',
        kind: CategoryKind.income,
        icon: Symbols.category_rounded,
        color: 0xFF78909C,
      ),
    ];

    var expenseOrder = 0;
    var incomeOrder = 0;
    await batch((batch) {
      batch.insertAll(categories, [
        for (final seed in seeds)
          CategoriesCompanion.insert(
            name: seed.name,
            kind: seed.kind.storageValue,
            iconCodePoint: seed.icon.codePoint,
            colorValue: seed.color,
            isSystem: Value(seed.isSystem),
            sortOrder: Value(
              seed.kind == CategoryKind.expense
                  ? expenseOrder++
                  : incomeOrder++,
            ),
          ),
      ]);
    });
  }
}

class _CategorySeed {
  const _CategorySeed({
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    this.isSystem = false,
  });

  final String name;
  final CategoryKind kind;
  final IconData icon;
  final int color;
  final bool isSystem;
}
