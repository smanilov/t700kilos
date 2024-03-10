import 'package:intl/intl.dart';

/// Parses the entered time string. Assumes the time string is formatted
/// according to [_formatEnteredTime].
///
/// [now] is the current day. If null, then 1st Jan, year 0 is used.
///
/// Returns a date consisting of the current day and the parsed time or null
/// if parsing failed.
DateTime? tryParseEnteredTime(String value, {DateTime? now}) {
  // Accept 9 or 11 as hours.
  if (value.length > 0 && value.length < 3) {
    final hours = int.tryParse(value);
    if (hours == null) return null;
    if (hours < 0 || hours > 23) return null;
    return DateTime(
        now?.year ?? 0, now?.month ?? 1, now?.day ?? 1, hours, 0);
  }

  // Accept 917 or 1142 as 9:17 or 11:42
  if (value.length >= 3 && value.length < 5) {
    final hours = int.tryParse(value.substring(0, value.length - 2));
    final minutes = int.tryParse(value.substring(value.length - 2));
    if (hours == null || minutes == null) return null;
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return null;
    return DateTime(
        now?.year ?? 0, now?.month ?? 1, now?.day ?? 1, hours, minutes);
  }

  if (value.length != 5) return null;
  if (!value.contains(':')) return null;

  final parts = value.split(':');
  if (parts.length != 2) return null;
  if (parts[0].length != 2 || parts[1].length != 2) return null;

  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);

  if (hours == null || minutes == null) return null;
  if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return null;

  return DateTime(
      now?.year ?? 0, now?.month ?? 1, now?.day ?? 1, hours, minutes);
}

/// Prints [_enteredTime] as a string that is formatted consistently with
/// [_tryParseEnteredTime].
String formatEnteredTime(DateTime enteredTime) {
  final hh = NumberFormat('00').format(enteredTime.hour);
  final mm = NumberFormat('00').format(enteredTime.minute);

  return '$hh:$mm';
}

String formatDate(DateTime date) {
  final yyyy = NumberFormat('0000').format(date.year);
  final mm = NumberFormat('00').format(date.month);
  final dd = NumberFormat('00').format(date.day);

  return '$yyyy-$mm-$dd';
}
