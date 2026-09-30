import 'package:drift/native.dart';
import 'package:ferikmoney/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v1 to v2 migration preserves IDs, balances, and transactions',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      raw.execute('''
      CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance INTEGER NOT NULL,
        icon TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
      CREATE TABLE transactions (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
        destination_account_id TEXT REFERENCES accounts(id) ON DELETE RESTRICT,
        category_id TEXT REFERENCES categories(id) ON DELETE RESTRICT,
        note TEXT,
        transaction_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
      final time = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
      raw.execute('INSERT INTO accounts VALUES (?, ?, ?, ?, ?, ?, ?)', [
        'wallet-v1',
        'Wallet lama',
        'bank',
        1000000,
        'account_balance',
        time,
        time,
      ]);
      raw.execute('INSERT INTO categories VALUES (?, ?, ?, ?, ?)', [
        'category-v1',
        'Kategori lama',
        'expense',
        'label',
        time,
      ]);
      raw.execute(
        'INSERT INTO transactions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'transaction-v1',
          'expense',
          125000,
          'wallet-v1',
          null,
          'category-v1',
          'Tetap tersimpan',
          time,
          time,
          time,
        ],
      );
      raw.userVersion = 1;

      final database = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(database.close);

      final accounts = await database.getAllAccounts();
      final categories = await database.getAllCategories();
      final transactions = await database.getAllTransactions();

      expect(
        accounts.singleWhere((item) => item.id == 'wallet-v1').initialBalance,
        1000000,
      );
      expect(
        accounts.singleWhere((item) => item.id == 'wallet-v1').isArchived,
        isFalse,
      );
      expect(categories.any((item) => item.id == 'category-v1'), isTrue);
      expect(categories.any((item) => item.id == 'expense-education'), isTrue);
      expect(transactions.single.id, 'transaction-v1');
      expect(await database.accountBalance('wallet-v1'), 875000);
      expect(database.schemaVersion, 2);
    },
  );
}
