String _two(int value) => value.toString().padLeft(2, '0');

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}';

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String todayKey([DateTime? now]) => dateKey(now ?? DateTime.now());

DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

DateTime nextMonth(DateTime date) => DateTime(date.year, date.month + 1);

String monthStartKey(DateTime month) => dateKey(monthStart(month));

String monthEndKeyExclusive(DateTime month) => dateKey(nextMonth(month));

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime clampDay(int year, int month, int day) {
  final last = daysInMonth(year, month);
  return DateTime(year, month, day > last ? last : day);
}

List<DateTime> monthsEndingAt(DateTime end, int count) {
  final base = monthStart(end);
  return List<DateTime>.generate(
    count,
    (index) => DateTime(base.year, base.month - (count - 1 - index)),
  );
}

bool isAfterToday(DateTime date, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final candidate = DateTime(date.year, date.month, date.day);
  final current = DateTime(today.year, today.month, today.day);
  return candidate.isAfter(current);
}

String addMonthsToKey(String key, int months) {
  final date = parseDateKey(key);
  return dateKey(DateTime(date.year, date.month + months, date.day));
}
