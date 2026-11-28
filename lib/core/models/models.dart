import '../db/database.dart';

enum WalletType {
  cash,
  bank,
  ewallet,
  other;

  static WalletType parse(String value) => WalletType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => WalletType.other,
  );

  String get storageValue => name;
}

enum CategoryKind {
  income,
  expense;

  static CategoryKind parse(String value) => CategoryKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => CategoryKind.expense,
  );

  String get storageValue => name;
}

class WalletBalance {
  const WalletBalance({required this.wallet, required this.balance});

  final Wallet wallet;
  final int balance;

  bool get isNegative => balance < 0;
}

class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  static const empty = MonthSummary(income: 0, expense: 0, transactionCount: 0);

  final int income;
  final int expense;
  final int transactionCount;

  int get net => income - expense;
  bool get hasData => transactionCount > 0;
}

enum ActivityKind { income, expense, transfer }

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    required this.walletName,
    required this.title,
    required this.iconCodePoint,
    this.note = '',
    this.isTransfer = false,
  });

  final int id;
  final ActivityKind kind;
  final int amount;
  final String date;
  final String walletName;
  final String title;
  final int iconCodePoint;
  final String note;
  final bool isTransfer;

  bool get isIncome => kind == ActivityKind.income;
}

class CategoryTotal {
  const CategoryTotal({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String name;
  final int amount;
  final double percentage;
  final int iconCodePoint;
  final int colorValue;
}

class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.summary,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
    required this.trend,
  });

  static const empty = AnalyticsSnapshot(
    summary: MonthSummary.empty,
    expenseBreakdown: [],
    incomeBreakdown: [],
    trend: [],
  );

  final MonthSummary summary;
  final List<CategoryTotal> expenseBreakdown;
  final List<CategoryTotal> incomeBreakdown;
  final List<TrendPoint> trend;

  bool get hasData => summary.hasData;
}

class DebtStatus {
  const DebtStatus({
    required this.entry,
    required this.paid,
    required this.remaining,
    required this.isSettled,
    required this.isOverdue,
    required this.payments,
  });

  final DebtEntry entry;
  final int paid;
  final int remaining;
  final bool isSettled;
  final bool isOverdue;
  final List<DebtPayment> payments;

  bool get isUtang => entry.direction == 'utang';
  bool get isCommitted => entry.principalTransactionId != null;
}

class DebtSummary {
  const DebtSummary({required this.totalUtang, required this.totalPiutang});

  static const empty = DebtSummary(totalUtang: 0, totalPiutang: 0);

  final int totalUtang;
  final int totalPiutang;
}
