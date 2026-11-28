import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../dates/date_keys.dart';

String formatDateLabel(BuildContext context, String key) =>
    MaterialLocalizations.of(context).formatMediumDate(parseDateKey(key));

String formatMonthLabel(DateTime month) =>
    DateFormat.yMMMM('id_ID').format(month);

String formatMonthShort(DateTime month) =>
    DateFormat.MMM('id_ID').format(month);

String monthName(int month) =>
    DateFormat.MMMM('id_ID').format(DateTime(2000, month));
