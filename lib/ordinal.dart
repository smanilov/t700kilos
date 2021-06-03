/// Returns the ordinal version of the given number.
///
/// Works only with the range from 1 to 31.
///
/// Returns null if input is out of range.
String? ordinal(int number) {
  if (number < 1 || number > 31) return null;

  if (number > 10 && number < 20) return '${number}th';

  final suffixes = ['th', 'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th'];

  return '$number${suffixes[number % 10]}';
}

/// Returns the first three letters of the day of the week.
///
/// Works only with the range from 1 to 7.
///
/// Returns null if input is out of range.
String? threeLetterDayOfWeek(int number) {
  if (number < 1 || number > 31) return null;

  return [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ][number - 1];
}

/// Returns the first three letters of the given month.
///
/// Works only with the range from 1 to 12.
///
/// Returns null if input is out of range.
String? threeLetterMonth(int number) {
  if (number < 1 || number > 12) return null;

  return [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][number - 1];
}
