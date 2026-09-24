import 'package:intl/intl.dart';

String relativeDateLabel(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Hari ini';
  if (difference == 1) return 'Kemarin';
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

String monthLabel(DateTime date) =>
    DateFormat('MMMM yyyy', 'id_ID').format(date);
