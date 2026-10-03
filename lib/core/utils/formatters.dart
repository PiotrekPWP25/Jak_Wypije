import 'package:intl/intl.dart';

final NumberFormat _pln =
    NumberFormat.currency(locale: 'pl_PL', symbol: 'zł', decimalDigits: 2);
final NumberFormat _plnWhole =
    NumberFormat.currency(locale: 'pl_PL', symbol: 'zł', decimalDigits: 0);

/// Formats an amount in Polish złoty, e.g. `12,50 zł`.
String formatPln(num amount, {bool whole = false}) =>
    (whole ? _plnWhole : _pln).format(amount);

/// `450 m` or `1,2 km`.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Minutes from midnight to `HH:mm` (wraps after midnight).
String formatClock(int minutesFromMidnight) {
  final minutes = minutesFromMidnight % (24 * 60);
  final hours = (minutes ~/ 60).toString().padLeft(2, '0');
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return '$hours:$rest';
}

/// `45 min`, `1 h`, `1 h 20 min`.
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String formatDate(DateTime date) =>
    DateFormat('d MMM yyyy, HH:mm', 'pl_PL').format(date);

String formatShortDate(DateTime date) =>
    DateFormat('d MMM', 'pl_PL').format(date);

/// Polish plural forms: 1 bar, 2 bary, 5 barów.
String pluralize(int count, String one, String few, String many) {
  if (count == 1) return one;
  final lastDigit = count % 10;
  final lastTwo = count % 100;
  if (lastDigit >= 2 && lastDigit <= 4 && (lastTwo < 12 || lastTwo > 14)) {
    return few;
  }
  return many;
}
