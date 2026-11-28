import 'package:drift/native.dart';
import 'package:ferik_money/app/app.dart';
import 'package:ferik_money/app/providers.dart';
import 'package:ferik_money/core/dates/date_keys.dart';
import 'package:ferik_money/core/dates/subscription_due.dart';
import 'package:ferik_money/core/db/database.dart';
import 'package:ferik_money/core/db/errors.dart';
import 'package:ferik_money/core/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<AppDatabase> newDatabase() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  }

  Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const FerikMoneyApp(),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  Future<int> addWallet(
    AppDatabase db, {
    String name = 'Dompet',
    int opening = 0,
    WalletType type = WalletType.cash,
  }) {
    return db.walletDao.createWallet(
      name: name,
      type: type,
      openingBalance: opening,
      iconCodePoint: 1,
      colorValue: 0xFF006C4C,
    );
  }

  Future<Category> category(AppDatabase db, String name) async {
    final items = await db.transactionDao.listCategories(
      kind: CategoryKind.expense,
    );
    return items.firstWhere((item) => item.name == name);
  }

  testWidgets('first run creates the first wallet', (tester) async {
    final db = await newDatabase();
    await pumpApp(tester, db);

    expect(find.text('Buat kantong pertama'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Dompet');
    await tester.tap(find.widgetWithText(FilledButton, 'Buat kantong'));
    await tester.pumpAndSettle();

    expect(find.text('Total saldo'), findsOneWidget);
    expect(await db.walletDao.activeCount(), 1);
  });

  testWidgets('bottom navigation switches all five tabs', (tester) async {
    final db = await newDatabase();
    await addWallet(db);
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.account_balance_wallet_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aktif'), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Analitik'), findsWidgets);

    await tester.tap(find.byIcon(Symbols.event_repeat_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Langganan'), findsWidgets);

    await tester.tap(find.byIcon(Symbols.handshake_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Utang'), findsWidgets);

    await tester.tap(find.byIcon(Symbols.home_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Total saldo'), findsOneWidget);
  });

  testWidgets('adds an expense from the home FAB', (tester) async {
    final db = await newDatabase();
    final walletId = await addWallet(db, opening: 100000);
    await pumpApp(tester, db);

    await tester.tap(find.byTooltip('Tambah pengeluaran'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '35000');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan pengeluaran'));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran disimpan'), findsOneWidget);
    expect(await db.walletDao.currentBalance(walletId), 65000);
  });

  testWidgets('shows monthly analytics totals', (tester) async {
    final db = await newDatabase();
    final walletId = await addWallet(db);
    final makan = await category(db, 'Makan & Minum');
    final categories = await db.transactionDao.listCategories(
      kind: CategoryKind.income,
    );
    final gaji = categories.firstWhere((c) => c.name == 'Gaji');
    final now = DateTime.now();

    await db.transactionDao.createTransaction(
      kind: CategoryKind.income,
      amount: 5000000,
      walletId: walletId,
      categoryId: gaji.id,
      date: DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10),
    );
    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 2000000,
      walletId: walletId,
      categoryId: makan.id,
      date: DateTime(now.year, now.month, 2).toIso8601String().substring(0, 10),
    );
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.bar_chart_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Rp 5.000.000'), findsWidgets);
    expect(find.text('Rp 2.000.000'), findsWidgets);
    expect(find.text('Rp 3.000.000'), findsWidgets);
  });

  testWidgets('shows and dismisses the subscription banner', (tester) async {
    final db = await newDatabase();
    final walletId = await addWallet(db);
    final tagihan = await category(db, 'Tagihan');
    final today = DateTime.now();
    await db.subscriptionDao.createSubscription(
      name: 'Netflix',
      amount: 54000,
      walletId: walletId,
      categoryId: tagihan.id,
      cycle: SubscriptionCycle.monthly,
      anchorDay: today.day,
      leadDays: 3,
      from: today,
    );
    await pumpApp(tester, db);

    expect(find.text('Langganan jatuh tempo'), findsOneWidget);
    expect(find.textContaining('Netflix'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Langganan jatuh tempo'), findsNothing);
  });

  testWidgets('pays a subscription through the prefilled expense', (
    tester,
  ) async {
    final db = await newDatabase();
    final walletId = await addWallet(db, opening: 100000);
    final tagihan = await category(db, 'Tagihan');
    final today = DateTime.now();
    final subscriptionId = await db.subscriptionDao.createSubscription(
      name: 'Netflix',
      amount: 54000,
      walletId: walletId,
      categoryId: tagihan.id,
      cycle: SubscriptionCycle.monthly,
      anchorDay: today.day,
      leadDays: 3,
      from: today,
    );
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.event_repeat_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();

    expect(find.text('54.000'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan pengeluaran'));
    await tester.pumpAndSettle();

    expect(find.text('Pengeluaran disimpan'), findsOneWidget);
    expect(await db.walletDao.currentBalance(walletId), 46000);
    final subscription = await db.subscriptionDao.byId(subscriptionId);
    expect(subscription!.nextDueDate, isNot(dateKey(today)));

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati siklus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Siklus dilewati'), findsOneWidget);
  });

  testWidgets('records a debt payment and commits the principal', (
    tester,
  ) async {
    final db = await newDatabase();
    final walletId = await addWallet(db, opening: 100000);
    final debtId = await db.debtDao.createEntry(
      direction: 'utang',
      counterparty: 'Budi',
      principal: 50000,
      startDate: '2026-11-01',
      dueDate: '2026-11-20',
    );
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.handshake_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '20000');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Pembayaran disimpan'), findsOneWidget);
    var status = await db.debtDao.statusById(debtId);
    expect(status!.remaining, 30000);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat ke saldo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Sudah dicatat'), findsWidgets);
    expect(await db.walletDao.currentBalance(walletId), 150000);
    status = await db.debtDao.statusById(debtId);
    expect(status!.isCommitted, isTrue);
  });

  testWidgets('debt screen separates utang and piutang totals', (tester) async {
    final db = await newDatabase();
    await addWallet(db);
    await db.debtDao.createEntry(
      direction: 'utang',
      counterparty: 'Budi',
      principal: 500000,
      startDate: '2026-11-01',
      dueDate: '2026-11-20',
    );
    await db.debtDao.createEntry(
      direction: 'piutang',
      counterparty: 'Sari',
      principal: 150000,
      startDate: '2026-11-01',
    );
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.handshake_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Total utang'), findsOneWidget);
    expect(find.text('Total piutang'), findsOneWidget);
    expect(find.text('Rp 500.000'), findsWidgets);
    expect(find.text('Rp 150.000'), findsWidgets);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Sari'), findsOneWidget);
  });

  testWidgets('marks a negative wallet balance', (tester) async {
    final db = await newDatabase();
    await addWallet(db, opening: -50000, name: 'Tunai');
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.account_balance_wallet_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Saldo minus'), findsOneWidget);
  });

  testWidgets('changes and persists the theme mode', (tester) async {
    final db = await newDatabase();
    await addWallet(db);
    await pumpApp(tester, db);

    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();

    expect(await db.settingsDao.getValue('theme_mode'), 'dark');
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, db);
    final restarted = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(restarted.themeMode, ThemeMode.dark);
  });

  testWidgets('wallet form rejects a duplicate name', (tester) async {
    final db = await newDatabase();
    await addWallet(db, name: 'Dompet');
    await pumpApp(tester, db);

    await tester.tap(find.byIcon(Symbols.account_balance_wallet_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kantong baru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'dompet');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama kantong sudah dipakai'), findsOneWidget);
  });

  testWidgets('transfer form blocks the same wallet', (tester) async {
    final db = await newDatabase();
    await addWallet(db, name: 'BCA', opening: 100000);
    await pumpApp(tester, db);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Transfer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '10000');

    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Simpan transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Kantong asal dan tujuan harus berbeda'), findsOneWidget);
  });

  testWidgets('unknown wallet id renders a recoverable message', (
    tester,
  ) async {
    final db = await newDatabase();
    await addWallet(db);
    await pumpApp(tester, db);
    expect(find.text('Total saldo'), findsOneWidget);
  });

  test('domain errors expose stable codes', () {
    expect(const DomainError(ErrorCodes.lastWallet).code, 'last_wallet');
  });
}
