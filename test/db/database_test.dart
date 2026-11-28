import 'package:drift/native.dart';
import 'package:ferik_money/core/dates/subscription_due.dart';
import 'package:ferik_money/core/db/daos/settings_dao.dart';
import 'package:ferik_money/core/db/database.dart';
import 'package:ferik_money/core/db/errors.dart';
import 'package:ferik_money/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createWallet({
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

  Future<Category> category(String name, CategoryKind kind) async {
    final items = await db.transactionDao.listCategories(kind: kind);
    return items.firstWhere((item) => item.name == name);
  }

  test('seeds default categories exactly once', () async {
    final first = await db.transactionDao.listCategories(activeOnly: false);
    final second = await db.transactionDao.listCategories(activeOnly: false);
    expect(first.length, 13);
    expect(second.length, 13);
    expect(first.where((c) => c.isSystem), hasLength(1));
  });

  test('derives wallet balances from income, expense, and transfers', () async {
    final a = await createWallet(
      name: 'BCA',
      opening: 100000,
      type: WalletType.bank,
    );
    final b = await createWallet(
      name: 'GoPay',
      opening: 50000,
      type: WalletType.ewallet,
    );
    final makan = await category('Makan & Minum', CategoryKind.expense);
    final gaji = await category('Gaji', CategoryKind.income);

    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 25000,
      walletId: a,
      categoryId: makan.id,
      date: '2026-11-01',
    );
    await db.transactionDao.createTransaction(
      kind: CategoryKind.income,
      amount: 50000,
      walletId: a,
      categoryId: gaji.id,
      date: '2026-11-02',
    );
    await db.transactionDao.createTransfer(
      sourceWalletId: a,
      destinationWalletId: b,
      amount: 100000,
      fee: 6500,
      date: '2026-11-03',
    );

    expect(await db.walletDao.currentBalance(a), 18500);
    expect(await db.walletDao.currentBalance(b), 150000);
  });

  test('editing and deleting a transaction re-derives balances', () async {
    final a = await createWallet(name: 'BCA', opening: 100000);
    final b = await createWallet(name: 'Mandiri', opening: 0);
    final makan = await category('Makan & Minum', CategoryKind.expense);
    final id = await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 20000,
      walletId: a,
      categoryId: makan.id,
      date: '2026-11-01',
    );

    await db.transactionDao.updateTransaction(
      id: id,
      kind: CategoryKind.expense,
      amount: 30000,
      walletId: b,
      categoryId: makan.id,
      date: '2026-11-01',
    );
    expect(await db.walletDao.currentBalance(a), 100000);
    expect(await db.walletDao.currentBalance(b), -30000);

    await db.transactionDao.deleteTransaction(id);
    expect(await db.walletDao.currentBalance(b), 0);
  });

  test('rejects future dates and invalid transfers', () async {
    final a = await createWallet(name: 'A');
    final makan = await category('Makan & Minum', CategoryKind.expense);

    expect(
      () => db.transactionDao.createTransaction(
        kind: CategoryKind.expense,
        amount: 1000,
        walletId: a,
        categoryId: makan.id,
        date: '2999-01-01',
      ),
      throwsA(isA<DomainError>()),
    );
    expect(
      () => db.transactionDao.createTransfer(
        sourceWalletId: a,
        destinationWalletId: a,
        amount: 1000,
        fee: 0,
        date: '2026-11-01',
      ),
      throwsA(isA<DomainError>()),
    );
  });

  test('editing and deleting a transfer keeps both balances correct',
      () async {
    final a = await createWallet(name: 'BCA', opening: 100000);
    final b = await createWallet(name: 'GoPay', opening: 0);
    final id = await db.transactionDao.createTransfer(
      sourceWalletId: a,
      destinationWalletId: b,
      amount: 40000,
      fee: 6500,
      date: '2026-11-01',
    );
    expect(await db.walletDao.currentBalance(a), 53500);
    expect(await db.walletDao.currentBalance(b), 40000);

    await db.transactionDao.updateTransfer(
      id: id,
      sourceWalletId: a,
      destinationWalletId: b,
      amount: 50000,
      fee: 0,
      date: '2026-11-01',
    );
    expect(await db.walletDao.currentBalance(a), 50000);
    expect(await db.walletDao.currentBalance(b), 50000);

    await db.transactionDao.deleteTransfer(id);
    expect(await db.walletDao.currentBalance(a), 100000);
    expect(await db.walletDao.currentBalance(b), 0);
  });

  test('analytics exclude transfers and include fees', () async {
    final wallet = await createWallet(name: 'BCA', opening: 0);
    final other = await createWallet(name: 'GoPay', opening: 0);
    final makan = await category('Makan & Minum', CategoryKind.expense);
    final gaji = await category('Gaji', CategoryKind.income);
    final month = DateTime(2026, 11);

    await db.transactionDao.createTransaction(
      kind: CategoryKind.income,
      amount: 5000000,
      walletId: wallet,
      categoryId: gaji.id,
      date: '2026-11-01',
    );
    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 2000000,
      walletId: wallet,
      categoryId: makan.id,
      date: '2026-11-02',
    );
    await db.transactionDao.createTransfer(
      sourceWalletId: wallet,
      destinationWalletId: other,
      amount: 1000000,
      fee: 6500,
      date: '2026-11-03',
    );

    final snapshot = await db.analyticsDao.loadSnapshot(month: month);
    expect(snapshot.summary.income, 5000000);
    expect(snapshot.summary.expense, 2006500);
    expect(snapshot.summary.net, 2993500);
    expect(snapshot.expenseBreakdown.first.name, 'Makan & Minum');
    expect(snapshot.expenseBreakdown.first.amount, 2000000);
    expect(snapshot.expenseBreakdown.last.name, '');
    expect(snapshot.expenseBreakdown.last.amount, 6500);
    expect(snapshot.trend, hasLength(6));
    expect(snapshot.trend.last.income, 5000000);
  });

  test('archived categories stay in reports but leave pickers', () async {
    final wallet = await createWallet(name: 'BCA');
    final makan = await category('Makan & Minum', CategoryKind.expense);
    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 10000,
      walletId: wallet,
      categoryId: makan.id,
      date: '2026-11-01',
    );
    await db.transactionDao.archiveCategory(makan.id);

    final active = await db.transactionDao.listCategories(
      kind: CategoryKind.expense,
    );
    expect(active.any((c) => c.id == makan.id), isFalse);

    final snapshot = await db.analyticsDao.loadSnapshot(
      month: DateTime(2026, 11),
    );
    expect(
      snapshot.expenseBreakdown.any((item) => item.name == 'Makan & Minum'),
      isTrue,
    );
  });

  test('wallet archive and delete guards', () async {
    final only = await createWallet(name: 'Only');
    expect(() => db.walletDao.archiveWallet(only), throwsA(isA<DomainError>()));

    final second = await createWallet(name: 'Second');
    await db.walletDao.archiveWallet(second);
    final all = await db.walletDao.all();
    expect(all.firstWhere((w) => w.id == second).archivedAt, isNotNull);

    final makan = await category('Makan & Minum', CategoryKind.expense);
    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 1000,
      walletId: only,
      categoryId: makan.id,
      date: '2026-11-01',
    );
    expect(() => db.walletDao.deleteWallet(only), throwsA(isA<DomainError>()));
  });

  test('subscription due cycle clamps and advances', () async {
    final wallet = await createWallet(name: 'BCA');
    final tagihan = await category('Tagihan', CategoryKind.expense);
    final id = await db.subscriptionDao.createSubscription(
      name: 'Netflix',
      amount: 54000,
      walletId: wallet,
      categoryId: tagihan.id,
      cycle: SubscriptionCycle.monthly,
      anchorDay: 31,
      leadDays: 3,
      from: DateTime(2026, 2, 10),
    );

    var entry = await db.subscriptionDao.byId(id);
    expect(entry!.nextDueDate, '2026-02-28');

    await db.subscriptionDao.completeCycle(id);
    entry = await db.subscriptionDao.byId(id);
    expect(entry!.nextDueDate, '2026-03-31');

    await db.subscriptionDao.updateSubscription(
      id: id,
      name: 'Netflix',
      amount: 60000,
      walletId: wallet,
      categoryId: tagihan.id,
      cycle: SubscriptionCycle.monthly,
      anchorDay: 31,
      leadDays: 3,
      active: true,
    );
    entry = await db.subscriptionDao.byId(id);
    expect(entry!.amount, 60000);
    expect(entry.nextDueDate, '2026-03-31');
  });

  test('debt entries stay out of balances until committed', () async {
    final wallet = await createWallet(name: 'BCA', opening: 100000);
    final gaji = await category('Gaji', CategoryKind.income);
    final makan = await category('Makan & Minum', CategoryKind.expense);

    final debtId = await db.debtDao.createEntry(
      direction: 'utang',
      counterparty: 'Budi',
      principal: 50000,
      startDate: '2026-11-01',
    );
    expect(await db.walletDao.currentBalance(wallet), 100000);

    var status = await db.debtDao.statusById(debtId);
    expect(status!.remaining, 50000);
    expect(status.isCommitted, isFalse);

    await db.debtDao.commitPrincipal(
      debtId: debtId,
      walletId: wallet,
      categoryId: gaji.id,
    );
    expect(await db.walletDao.currentBalance(wallet), 150000);
    status = await db.debtDao.statusById(debtId);
    expect(status!.isCommitted, isTrue);
    expect(
      () => db.debtDao.commitPrincipal(
        debtId: debtId,
        walletId: wallet,
        categoryId: gaji.id,
      ),
      throwsA(isA<DomainError>()),
    );

    await db.debtDao.recordPayment(
      debtId: debtId,
      amount: 20000,
      date: '2026-11-02',
      commitWalletId: wallet,
      commitCategoryId: makan.id,
    );
    expect(await db.walletDao.currentBalance(wallet), 130000);
    status = await db.debtDao.statusById(debtId);
    expect(status!.remaining, 30000);

    expect(
      () => db.debtDao.recordPayment(
        debtId: debtId,
        amount: 999999,
        date: '2026-11-03',
      ),
      throwsA(isA<DomainError>()),
    );
  });

  test('deleting a committed transaction clears the link', () async {
    final wallet = await createWallet(name: 'BCA', opening: 0);
    final gaji = await category('Gaji', CategoryKind.income);
    final debtId = await db.debtDao.createEntry(
      direction: 'utang',
      counterparty: 'Budi',
      principal: 50000,
      startDate: '2026-11-01',
      commitWalletId: wallet,
      commitCategoryId: gaji.id,
    );
    var status = await db.debtDao.statusById(debtId);
    final transactionId = status!.entry.principalTransactionId!;

    await db.transactionDao.deleteTransaction(transactionId);
    status = await db.debtDao.statusById(debtId);
    expect(status!.isCommitted, isFalse);
    expect(await db.walletDao.currentBalance(wallet), 0);
  });

  test('deleting a debt keeps committed transactions', () async {
    final wallet = await createWallet(name: 'BCA', opening: 0);
    final gaji = await category('Gaji', CategoryKind.income);
    final debtId = await db.debtDao.createEntry(
      direction: 'utang',
      counterparty: 'Budi',
      principal: 50000,
      startDate: '2026-11-01',
      commitWalletId: wallet,
      commitCategoryId: gaji.id,
    );
    await db.debtDao.deleteEntry(debtId);
    expect(await db.walletDao.currentBalance(wallet), 50000);
    expect(await db.debtDao.loadStatuses(), isEmpty);
  });

  test('settings persist theme mode', () async {
    expect(await db.settingsDao.getValue(SettingsDao.themeModeKey), isNull);
    await db.settingsDao.setValue(SettingsDao.themeModeKey, 'dark');
    expect(await db.settingsDao.getValue(SettingsDao.themeModeKey), 'dark');
  });

  test('balance stream reacts to a new expense', () async {
    final wallet = await createWallet(name: 'BCA', opening: 100000);
    final makan = await category('Makan & Minum', CategoryKind.expense);
    final values = <int>[];
    final subscription = db.walletDao.watchBalances().listen(
      (items) => values.add(items.first.balance),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await db.transactionDao.createTransaction(
      kind: CategoryKind.expense,
      amount: 25000,
      walletId: wallet,
      categoryId: makan.id,
      date: '2026-11-01',
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(values.last, 75000);
    await subscription.cancel();
  });
}
