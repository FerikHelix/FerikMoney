import 'package:drift/drift.dart';

import '../../dates/date_keys.dart';
import '../../models/models.dart';
import '../database.dart';
import '../tables.dart';

part 'analytics_dao.g.dart';

@DriftAccessor(tables: [Transactions, Transfers, Categories])
class AnalyticsDao extends DatabaseAccessor<AppDatabase>
    with _$AnalyticsDaoMixin {
  AnalyticsDao(super.db);

  Stream<AnalyticsSnapshot> watchSnapshot({
    required DateTime month,
    int? walletId,
  }) async* {
    yield await loadSnapshot(month: month, walletId: walletId);
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables([transactions, transfers, categories]),
    )) {
      yield await loadSnapshot(month: month, walletId: walletId);
    }
  }

  Future<AnalyticsSnapshot> loadSnapshot({
    required DateTime month,
    int? walletId,
  }) async {
    final selected = monthStart(month);
    final from = monthStartKey(selected);
    final to = monthEndKeyExclusive(selected);

    final summary = await _loadSummary(from: from, to: to, walletId: walletId);
    final expenseBreakdown = await _loadBreakdown(
      kind: CategoryKind.expense,
      from: from,
      to: to,
      walletId: walletId,
    );
    final incomeBreakdown = await _loadBreakdown(
      kind: CategoryKind.income,
      from: from,
      to: to,
      walletId: walletId,
    );
    final trend = await _loadTrend(selected: selected, walletId: walletId);

    return AnalyticsSnapshot(
      summary: summary,
      expenseBreakdown: expenseBreakdown,
      incomeBreakdown: incomeBreakdown,
      trend: trend,
    );
  }

  Future<MonthSummary> _loadSummary({
    required String from,
    required String to,
    int? walletId,
  }) async {
    final walletClause = walletId == null ? '' : ' AND t.wallet_id = ?';
    final variables = <Variable<Object>>[
      Variable.withString(from),
      Variable.withString(to),
      if (walletId != null) Variable.withInt(walletId),
    ];
    final row = await customSelect(
      '''
SELECT COALESCE(SUM(CASE WHEN t.kind = 'income' THEN t.amount ELSE 0 END), 0) AS income,
       COALESCE(SUM(CASE WHEN t.kind = 'expense' THEN t.amount ELSE 0 END), 0) AS expense,
       COUNT(*) AS transaction_count
FROM transactions t
WHERE t.date >= ? AND t.date < ?$walletClause
''',
      variables: variables,
      readsFrom: {transactions},
    ).getSingle();

    final feeWalletClause = walletId == null
        ? ''
        : ' AND tr.source_wallet_id = ?';
    final feeRow = await customSelect(
      '''
SELECT COALESCE(SUM(tr.fee), 0) AS fee,
       COALESCE(SUM(CASE WHEN tr.fee > 0 THEN 1 ELSE 0 END), 0) AS fee_count
FROM transfers tr
WHERE tr.date >= ? AND tr.date < ?$feeWalletClause
''',
      variables: [
        Variable.withString(from),
        Variable.withString(to),
        if (walletId != null) Variable.withInt(walletId),
      ],
      readsFrom: {transfers},
    ).getSingle();

    final fee = feeRow.read<int>('fee');
    final feeCount = feeRow.read<int>('fee_count');
    return MonthSummary(
      income: row.read<int>('income'),
      expense: row.read<int>('expense') + fee,
      transactionCount: row.read<int>('transaction_count') + feeCount,
    );
  }

  Future<List<CategoryTotal>> _loadBreakdown({
    required CategoryKind kind,
    required String from,
    required String to,
    int? walletId,
  }) async {
    final walletClause = walletId == null ? '' : ' AND t.wallet_id = ?';
    final rows = await customSelect(
      '''
SELECT c.name, c.icon_code_point, c.color_value, SUM(t.amount) AS amount
FROM transactions t
JOIN categories c ON c.id = t.category_id
WHERE t.kind = ? AND t.date >= ? AND t.date < ?$walletClause
GROUP BY c.id
ORDER BY amount DESC
''',
      variables: [
        Variable.withString(kind.storageValue),
        Variable.withString(from),
        Variable.withString(to),
        if (walletId != null) Variable.withInt(walletId),
      ],
      readsFrom: {transactions, categories},
    ).get();

    final totals = <CategoryTotal>[
      for (final row in rows)
        CategoryTotal(
          name: row.read<String>('name'),
          amount: row.read<int>('amount'),
          percentage: 0,
          iconCodePoint: row.read<int>('icon_code_point'),
          colorValue: row.read<int>('color_value'),
        ),
    ];

    if (kind == CategoryKind.expense) {
      final feeWalletClause = walletId == null
          ? ''
          : ' AND tr.source_wallet_id = ?';
      final feeRow = await customSelect(
        '''
SELECT COALESCE(SUM(tr.fee), 0) AS fee
FROM transfers tr
WHERE tr.date >= ? AND tr.date < ? AND tr.fee > 0$feeWalletClause
''',
        variables: [
          Variable.withString(from),
          Variable.withString(to),
          if (walletId != null) Variable.withInt(walletId),
        ],
        readsFrom: {transfers},
      ).getSingle();
      final fee = feeRow.read<int>('fee');
      if (fee > 0) {
        totals.add(
          CategoryTotal(
            name: '',
            amount: fee,
            percentage: 0,
            iconCodePoint: 0,
            colorValue: 0,
          ),
        );
      }
    }

    final total = totals.fold<int>(0, (sum, item) => sum + item.amount);
    totals.sort((a, b) => b.amount.compareTo(a.amount));
    return [
      for (final item in totals)
        CategoryTotal(
          name: item.name,
          amount: item.amount,
          percentage: total == 0 ? 0 : item.amount / total * 100,
          iconCodePoint: item.iconCodePoint,
          colorValue: item.colorValue,
        ),
    ];
  }

  Future<List<TrendPoint>> _loadTrend({
    required DateTime selected,
    int? walletId,
  }) async {
    final months = monthsEndingAt(selected, 6);
    final from = monthStartKey(months.first);
    final to = monthEndKeyExclusive(selected);
    final incomeByMonth = <String, int>{};
    final expenseByMonth = <String, int>{};

    final walletClause = walletId == null ? '' : ' AND t.wallet_id = ?';
    final rows = await customSelect(
      '''
SELECT substr(t.date, 1, 7) AS ym,
       COALESCE(SUM(CASE WHEN t.kind = 'income' THEN t.amount ELSE 0 END), 0) AS income,
       COALESCE(SUM(CASE WHEN t.kind = 'expense' THEN t.amount ELSE 0 END), 0) AS expense
FROM transactions t
WHERE t.date >= ? AND t.date < ?$walletClause
GROUP BY ym
''',
      variables: [
        Variable.withString(from),
        Variable.withString(to),
        if (walletId != null) Variable.withInt(walletId),
      ],
      readsFrom: {transactions},
    ).get();

    for (final row in rows) {
      final key = row.read<String>('ym');
      incomeByMonth[key] = row.read<int>('income');
      expenseByMonth[key] = row.read<int>('expense');
    }

    final feeWalletClause = walletId == null
        ? ''
        : ' AND tr.source_wallet_id = ?';
    final feeRows = await customSelect(
      '''
SELECT substr(tr.date, 1, 7) AS ym, COALESCE(SUM(tr.fee), 0) AS fee
FROM transfers tr
WHERE tr.date >= ? AND tr.date < ? AND tr.fee > 0$feeWalletClause
GROUP BY ym
''',
      variables: [
        Variable.withString(from),
        Variable.withString(to),
        if (walletId != null) Variable.withInt(walletId),
      ],
      readsFrom: {transfers},
    ).get();

    for (final row in feeRows) {
      final key = row.read<String>('ym');
      expenseByMonth[key] = (expenseByMonth[key] ?? 0) + row.read<int>('fee');
    }

    return [
      for (final month in months)
        TrendPoint(
          month: month,
          income: incomeByMonth[dateKey(month).substring(0, 7)] ?? 0,
          expense: expenseByMonth[dateKey(month).substring(0, 7)] ?? 0,
        ),
    ];
  }
}
