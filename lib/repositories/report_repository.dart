import '../database/app_database.dart';
import '../models/finance_models.dart';
import '../utils/balance_adjustment.dart';

class ReportRepository {
  const ReportRepository();

  ReportSnapshot build({
    required List<MoneyTransaction> transactions,
    required FinancePeriod period,
    required DateTime anchor,
    required int firstWeekday,
    DateTime? now,
  }) {
    final range = period.range(anchor, firstWeekday: firstWeekday);
    final current = now ?? DateTime.now();
    final isCurrent = range.contains(current);
    final effectiveEnd = isCurrent ? current : range.endExclusive;
    final duration = effectiveEnd.difference(range.start);
    final previousEnd = range.start;
    final previousStart = previousEnd.subtract(duration);
    var income = 0;
    var expense = 0;
    var previousExpense = 0;
    final expenseByCategory = <String, int>{};
    final incomeByCategory = <String, int>{};
    final trend = <DateTime, (int, int)>{};
    for (final transaction in transactions) {
      if (isAdjustmentCategory(transaction.categoryId)) continue;
      final date = transaction.transactionDate;
      final inCurrent =
          !date.isBefore(range.start) && date.isBefore(effectiveEnd);
      if (inCurrent) {
        if (transaction.type == 'income') {
          income += transaction.amount;
          if (transaction.categoryId != null) {
            incomeByCategory.update(
              transaction.categoryId!,
              (value) => value + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          }
        } else if (transaction.type == 'expense') {
          expense += transaction.amount;
          if (transaction.categoryId != null) {
            expenseByCategory.update(
              transaction.categoryId!,
              (value) => value + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          }
        }
        if (transaction.type == 'income' || transaction.type == 'expense') {
          final key = period == FinancePeriod.year
              ? DateTime(date.year, date.month)
              : DateTime(date.year, date.month, date.day);
          final old = trend[key] ?? (0, 0);
          trend[key] = transaction.type == 'income'
              ? (old.$1 + transaction.amount, old.$2)
              : (old.$1, old.$2 + transaction.amount);
        }
      }
      if (transaction.type == 'expense' &&
          !date.isBefore(previousStart) &&
          date.isBefore(previousEnd)) {
        previousExpense += transaction.amount;
      }
    }
    final points =
        trend.entries
            .map(
              (entry) => TrendPoint(
                date: entry.key,
                income: entry.value.$1,
                expense: entry.value.$2,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return ReportSnapshot(
      range: range,
      income: income,
      expense: expense,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      trend: points,
      previousExpense: previousExpense,
    );
  }
}
