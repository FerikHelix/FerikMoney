import '../database/app_database.dart';

enum FinancePeriod { week, month, year }

enum TransactionSort { newest, oldest, highest, lowest }

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

enum OccurrenceStatus { pending, created, skipped }

enum BudgetStatus { safe, approaching, over }

enum GoalTransferType { deposit, withdrawal }

extension FinancePeriodX on FinancePeriod {
  String get label => switch (this) {
    FinancePeriod.week => 'Minggu Ini',
    FinancePeriod.month => 'Bulan Ini',
    FinancePeriod.year => 'Tahun Ini',
  };

  FinanceDateRange range(DateTime anchor, {required int firstWeekday}) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      FinancePeriod.week => () {
        final offset = (day.weekday - firstWeekday + 7) % 7;
        final start = day.subtract(Duration(days: offset));
        return FinanceDateRange(start, start.add(const Duration(days: 7)));
      }(),
      FinancePeriod.month => FinanceDateRange(
        DateTime(day.year, day.month),
        DateTime(day.year, day.month + 1),
      ),
      FinancePeriod.year => FinanceDateRange(
        DateTime(day.year),
        DateTime(day.year + 1),
      ),
    };
  }
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get label => switch (this) {
    RecurrenceFrequency.daily => 'Harian',
    RecurrenceFrequency.weekly => 'Mingguan',
    RecurrenceFrequency.monthly => 'Bulanan',
    RecurrenceFrequency.yearly => 'Tahunan',
  };

  DateTime next(DateTime value) => switch (this) {
    RecurrenceFrequency.daily => value.add(const Duration(days: 1)),
    RecurrenceFrequency.weekly => value.add(const Duration(days: 7)),
    RecurrenceFrequency.monthly => _nextMonth(value),
    RecurrenceFrequency.yearly => _nextYear(value),
  };

  static DateTime _nextMonth(DateTime value) {
    final firstOfTarget = DateTime(value.year, value.month + 1);
    final lastDay = DateTime(value.year, value.month + 2, 0).day;
    final day = value.day > lastDay ? lastDay : value.day;
    return DateTime(
      firstOfTarget.year,
      firstOfTarget.month,
      day,
      value.hour,
      value.minute,
    );
  }

  static DateTime _nextYear(DateTime value) {
    final targetYear = value.year + 1;
    final lastDay = DateTime(targetYear, value.month + 1, 0).day;
    final day = value.day > lastDay ? lastDay : value.day;
    return DateTime(targetYear, value.month, day, value.hour, value.minute);
  }
}

extension BudgetStatusX on BudgetStatus {
  static BudgetStatus fromRatio(double ratio) {
    if (ratio >= 1) return BudgetStatus.over;
    if (ratio >= 0.8) return BudgetStatus.approaching;
    return BudgetStatus.safe;
  }

  String get label => switch (this) {
    BudgetStatus.safe => 'Aman',
    BudgetStatus.approaching => 'Mendekati batas',
    BudgetStatus.over => 'Melebihi budget',
  };
}

class FinanceDateRange {
  const FinanceDateRange(this.start, this.endExclusive);

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);
}

class TransactionWithTags {
  const TransactionWithTags({required this.transaction, required this.tags});

  final MoneyTransaction transaction;
  final List<Tag> tags;
}

class FinanceActivity {
  const FinanceActivity.transaction(TransactionWithTags value)
    : transaction = value,
      goalTransfer = null;

  const FinanceActivity.goalTransfer(SavingsGoalTransfer value)
    : transaction = null,
      goalTransfer = value;

  final TransactionWithTags? transaction;
  final SavingsGoalTransfer? goalTransfer;

  DateTime get date =>
      transaction?.transaction.transactionDate ?? goalTransfer!.transferDate;
  int get amount => transaction?.transaction.amount ?? goalTransfer!.amount;
  bool get isGoalTransfer => goalTransfer != null;
}

class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spent});

  final Budget budget;
  final int spent;

  double get ratio => budget.amount == 0 ? 0 : spent / budget.amount;
  int get remaining => budget.amount - spent;
  BudgetStatus get status => BudgetStatusX.fromRatio(ratio);
}

class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final int income;
  final int expense;
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.range,
    required this.income,
    required this.expense,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.trend,
    required this.previousExpense,
  });

  final FinanceDateRange range;
  final int income;
  final int expense;
  final Map<String, int> expenseByCategory;
  final Map<String, int> incomeByCategory;
  final List<TrendPoint> trend;
  final int previousExpense;

  int get net => income - expense;
}
