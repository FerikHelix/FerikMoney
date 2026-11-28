import 'package:ferik_money/core/dates/date_keys.dart';
import 'package:ferik_money/core/dates/subscription_due.dart';
import 'package:ferik_money/core/money/rupiah.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rupiah', () {
    test('formats grouped rupiah', () {
      expect(formatRupiah(1234567), 'Rp 1.234.567');
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(-50000), '-Rp 50.000');
    });

    test('parses digits and grouping', () {
      expect(parseRupiah('35.000'), 35000);
      expect(parseRupiah('Rp 1.234.567'), 1234567);
      expect(parseRupiah('abc'), null);
      expect(parseRupiah(''), null);
    });

    test('formats percentages', () {
      expect(formatPercentage(60), '60%');
      expect(formatPercentage(33.333), '33.3%');
    });
  });

  group('date keys', () {
    test('round trips a calendar date', () {
      final key = dateKey(DateTime(2026, 3, 1));
      expect(key, '2026-03-01');
      expect(parseDateKey(key), DateTime(2026, 3, 1));
    });

    test('builds month ranges', () {
      final month = DateTime(2026, 12, 15);
      expect(monthStartKey(month), '2026-12-01');
      expect(monthEndKeyExclusive(month), '2027-01-01');
    });

    test('returns six months ending at the selected month', () {
      final months = monthsEndingAt(DateTime(2026, 6, 1), 6);
      expect(months.first, DateTime(2026, 1));
      expect(months.last, DateTime(2026, 6));
    });

    test('clamps a day to the month length', () {
      expect(clampDay(2026, 2, 31), DateTime(2026, 2, 28));
      expect(clampDay(2024, 2, 31), DateTime(2024, 2, 29));
    });

    test('detects future dates by calendar day', () {
      final now = DateTime(2026, 5, 10, 23, 30);
      expect(isAfterToday(DateTime(2026, 5, 11), now), isTrue);
      expect(isAfterToday(DateTime(2026, 5, 10, 23, 59), now), isFalse);
    });
  });

  group('subscription due dates', () {
    test('clamps day 31 to February', () {
      final due = initialDueDate(
        cycle: SubscriptionCycle.monthly,
        anchorDay: 31,
        from: DateTime(2026, 2, 10),
      );
      expect(due, DateTime(2026, 2, 28));
    });

    test('advances from February back to day 31', () {
      final next = advanceDueDate(
        current: DateTime(2026, 2, 28),
        cycle: SubscriptionCycle.monthly,
        anchorDay: 31,
      );
      expect(next, DateTime(2026, 3, 31));
    });

    test('clamps leap day in a non-leap year', () {
      final due = initialDueDate(
        cycle: SubscriptionCycle.yearly,
        anchorDay: 29,
        anchorMonth: 2,
        from: DateTime(2026, 1, 1),
      );
      expect(due, DateTime(2026, 2, 28));
    });

    test('late payment does not drift the anchor day', () {
      final next = advanceDueDate(
        current: DateTime(2026, 1, 5),
        cycle: SubscriptionCycle.monthly,
        anchorDay: 5,
      );
      expect(next, DateTime(2026, 2, 5));
    });

    test('rolls to next month when this month is past', () {
      final due = initialDueDate(
        cycle: SubscriptionCycle.monthly,
        anchorDay: 5,
        from: DateTime(2026, 1, 10),
      );
      expect(due, DateTime(2026, 2, 5));
    });

    test('counts days until due', () {
      expect(daysUntil(DateTime(2026, 3, 15), DateTime(2026, 3, 10)), 5);
      expect(daysUntil(DateTime(2026, 3, 5), DateTime(2026, 3, 10)), -5);
    });
  });
}
