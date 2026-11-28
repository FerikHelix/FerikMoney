import 'date_keys.dart';

enum SubscriptionCycle {
  monthly,
  yearly;

  static SubscriptionCycle parse(String value) => SubscriptionCycle.values
      .firstWhere((cycle) => cycle.name == value, orElse: () => monthly);

  String get storageValue => name;
}

DateTime dueDateForMonth({
  required int year,
  required int month,
  required int anchorDay,
}) => clampDay(year, month, anchorDay);

DateTime initialDueDate({
  required SubscriptionCycle cycle,
  required int anchorDay,
  int? anchorMonth,
  required DateTime from,
}) {
  final today = DateTime(from.year, from.month, from.day);
  if (cycle == SubscriptionCycle.monthly) {
    var candidate = dueDateForMonth(
      year: today.year,
      month: today.month,
      anchorDay: anchorDay,
    );
    if (candidate.isBefore(today)) {
      candidate = dueDateForMonth(
        year: today.year,
        month: today.month + 1,
        anchorDay: anchorDay,
      );
    }
    return candidate;
  }

  final month = anchorMonth ?? today.month;
  var candidate = clampDay(today.year, month, anchorDay);
  if (candidate.isBefore(today)) {
    candidate = clampDay(today.year + 1, month, anchorDay);
  }
  return candidate;
}

DateTime advanceDueDate({
  required DateTime current,
  required SubscriptionCycle cycle,
  required int anchorDay,
  int? anchorMonth,
}) {
  if (cycle == SubscriptionCycle.monthly) {
    return dueDateForMonth(
      year: current.year,
      month: current.month + 1,
      anchorDay: anchorDay,
    );
  }
  return clampDay(current.year + 1, anchorMonth ?? current.month, anchorDay);
}

int daysUntil(DateTime due, DateTime from) {
  final a = DateTime(due.year, due.month, due.day);
  final b = DateTime(from.year, from.month, from.day);
  return a.difference(b).inDays;
}
