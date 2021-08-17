import 'package:built_value/built_value.dart';

import 'record.dart';

part 'morning_evening_analysis.g.dart';

/// Represents a time of day.
///
/// Unfortunately, the flutter TimeOfDay does not define comparison operators,
/// so we need to roll our own.
///
/// Can be over 24:00 to represent the small hours of the night (up to 28:00,
/// but not enforced).
abstract class TimeOfDay implements Built<TimeOfDay, TimeOfDayBuilder> {
  int get hours;

  int get minutes;

  TimeOfDay._();

  factory TimeOfDay(int hours, int minutes) =>
      _$TimeOfDay._(hours: hours, minutes: minutes);

  factory TimeOfDay.fromDateTime(DateTime dateTime) =>
      TimeOfDay(dateTime.hour, dateTime.minute);

  bool operator >(TimeOfDay other) {
    return hours > other.hours ||
        hours == other.hours && minutes > other.minutes;
  }

  bool operator >=(TimeOfDay other) {
    return this == other || this > other;
  }

  bool operator <(TimeOfDay other) {
    return other > this;
  }

  bool operator <=(TimeOfDay other) {
    return other >= this;
  }

  Duration operator -(TimeOfDay other) =>
      Duration(hours: hours - other.hours, minutes: minutes - other.minutes);

  /// Returns a derivative [TimeOfDay], offset by the given number of hours (can
  /// be negative).
  TimeOfDay addHours(int additionalHours) =>
      TimeOfDay(hours + additionalHours, minutes);
}

/// A short time range (five hours or less; not enforced) that possibly spans
/// midnight, e.g. (06:30 - 11:00), (09:30 - 10:30), (23:45 - 02:30), or
/// (01:30 - 03:30).
///
/// The length limit is used when interpreting ambiguous endpoints: e.g.
/// (27:00 - 04:00) is of length 1 hour; 01:00 - 26:00 -- also.
abstract class TimeRange implements Built<TimeRange, TimeRangeBuilder> {
  /// The start of the range: can be in the evening before midnight.
  TimeOfDay get start;

  /// The end of the range: can be in the morning after midnight.
  TimeOfDay get end;

  TimeRange._();

  factory TimeRange(TimeOfDay start, TimeOfDay end) =>
      _$TimeRange._(start: start, end: end);

  /// Whether this range contains the given [time]. The range is normalized as
  /// part of the comparison, so it does not need to be normalized in advance.
  bool containsTime(DateTime time) {
    final timeOfDay = TimeOfDay.fromDateTime(time);
    final normalizedStart =
        start >= TimeOfDay(24, 0) ? start.addHours(-24) : start;
    final normalizedEnd = end >= TimeOfDay(24, 0) ? end.addHours(-24) : end;

    return (normalizedStart <= normalizedEnd)
        ?
        // Simple case.
        normalizedStart <= timeOfDay && timeOfDay <= normalizedEnd
        :
        // Range spans midnight.
        timeOfDay <= normalizedEnd || normalizedStart <= timeOfDay;
  }
}

/// A pair of [TimeRange]s: one for the morning (starting at 4AM or later;
/// ending at 4PM or earlier) and one for the evening (starting at 4PM or later,
/// ending at 4AM or earlier).
abstract class MorningEveningRanges
    implements Built<MorningEveningRanges, MorningEveningRangesBuilder> {
  TimeRange get morningRange;

  TimeRange get eveningRange;

  MorningEveningRanges._();

  factory MorningEveningRanges(
          TimeRange morningRange, TimeRange eveningRange) =>
      _$MorningEveningRanges._(
          morningRange: morningRange, eveningRange: eveningRange);
}

abstract class MorningEveningRecords
    implements Built<MorningEveningRecords, MorningEveningRecordsBuilder> {
  List<Record> get morningRecords;

  List<Record> get eveningRecords;

  MorningEveningRecords._();

  factory MorningEveningRecords(
          List<Record> morningRecords, List<Record> eveningRecords) =>
      _$MorningEveningRecords._(
          morningRecords: morningRecords, eveningRecords: eveningRecords);
}

/// Analyses a list of records with the goal of determining which ones are
/// "morning records" and which one are "evening records". Otherwise, a record
/// is an "other record".
///
/// A "morning record" has a time between 4AM and 4PM. The most popular
/// five-hour subrange of this interval is computed from the given list of
/// records to give the "morning range".
///
/// The earliest record from each day that falls in the "morning range" is the
/// "morning record" for that day. A twist: "days" are offset by 4 hours, so
/// 3AM on June 6th is the day before than 5AM on June 6th. This is to align
/// them with what people perceive as days: the time between waking up in the
/// morning and going to bed at night.
///
/// An "evening record" is like a morning record, just between 4PM and 4AM. The
/// "latest" record in the "evening range" (see "morning range") for a given
/// 4-am-offset-day is the "evening record" for that day. Note that "latest"
/// means 1AM is later than 23PM, etc.
///
/// Example:
///
/// 2021.05.25 20:00 - in "evening range" - "other record" (not latest for day)
/// 2021.05.25 23:00 - in "evening range" - "evening record" (latest for day)
/// 2021.05.26 03:00 - in "other range"   - "other record" (out of range)
/// 2021.05.26 09:00 - in "morning range" - "morning record" (earliest for day)
/// 2021.05.26 12:00 - in "morning range" - "other record" (not earliest)
/// 2021.05.26 15:00 - in "other range"   - "other record" (out of range)
/// 2021.05.26 20:00 - in "evening range" - "other record" (not latest for day)
/// 2021.05.26 23:00 - in "evening range" - "evening record" (latest for day)
/// 2021.05.27 08:00 - in "morning range" - "morning record" (only for day)
/// 2021.05.27 21:00 - in "evening range" - "evening record (only for day)
///
/// Sorted times:
///
/// 08:00 - morning range
/// 09:00 - morning range
/// 12:00 - morning range
/// 15:00 - other range
/// 20:00 - evening range
/// 20:00 - evening range
/// 21:00 - evening range
/// 23:00 - evening range
/// 23:00 - evening range
/// 03:00 - other range
class MorningEveningAnalyser {
  /// Returns two empty lists if there aren't enough records.
  MorningEveningRecords computeMorningEveningRecords(List<Record> records) {
    if (records.isEmpty) {
      return MorningEveningRecords([], []);
    }

    try {
      final morningEveningRanges = _computeMorningEveningRanges(records);
      final sortedRecords = records.toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      bool isMorningRecord(Record r) =>
          morningEveningRanges.morningRange.containsTime(r.time);
      bool isEveningRecord(Record r) =>
          morningEveningRanges.eveningRange.containsTime(r.time);

      final morningRecords = _onlyOnePerDay(
          sortedRecords.where(isMorningRecord),
          earlierIsBetter: true);
      final eveningRecords = _onlyOnePerDay(
          sortedRecords.where(isEveningRecord),
          earlierIsBetter: false);

      return MorningEveningRecords(morningRecords, eveningRecords);
    } on NotEnoughDataException {
      // Expected exception when there are not enough records yet.
      return MorningEveningRecords([], []);
    }
  }

  MorningEveningRanges _computeMorningEveningRanges(List<Record> records) {
    final t4am = TimeOfDay(4, 0);
    final t4pm = TimeOfDay(16, 0);
    final timesOfDay = records.map((r) => TimeOfDay.fromDateTime(r.time));
    // Possible morning times: limited to (4am, 4pm).
    final morningTimes = timesOfDay.where((tod) => tod >= t4am && tod < t4pm);
    // Possible evening times: limited to (4pm, 4am). Times after midnight are
    // represented by an offset of 24:00, e.g. 3am is 27:00.
    final eveningTimes = timesOfDay
        .where((tod) => tod >= t4pm || tod < t4am)
        .map(
            (tod) => tod < t4am ? TimeOfDay(tod.hours + 24, tod.minutes) : tod);

    if (morningTimes.isEmpty || eveningTimes.isEmpty) {
      throw NotEnoughDataException(
          "_computeMorningEveningRanges called with a list that doesn't "
          'contain at least one possible morning and one possible evening '
          'record.');
    }

    return MorningEveningRanges(
        _mostPopularFiveHourWindow(morningTimes, earlierIsBetter: true),
        _mostPopularFiveHourWindow(eveningTimes, earlierIsBetter: false));
  }

  List<Record> _onlyOnePerDay(Iterable<Record> candidates,
      {required bool earlierIsBetter}) {
    final result = <Record>[];
    Record? candidate;
    for (final r in candidates) {
      // Note: this is verbose on purpose: conditions follow natural order.
      if (candidate == null) {
        // At the beginning the candidate will be null.
        candidate = r;
        continue;
      }
      // The following applies to the second or later elements.
      if (_inTheSameDay(candidate, r)) {
        // The current record is in the same day as the candidate, so...
        if (earlierIsBetter) {
          // ... ignore.
        } else {
          // ... update the candidate.
          candidate = r;
        }
        continue;
      } else {
        // We have reached the next day; commit the candidate and repeat.
        result.add(candidate);
        candidate = r;
      }
    }
    if (candidate != null) {
      // [allMorningRecords] was not empty: commit the last candidate.
      result.add(candidate);
    }
    return result;
  }
}

/// Returns the five hour window that contains the most items from [timesOfDay].
/// If [earlierIsBetter] is true, then ties are broken in favour of the earlier
/// period; otherwise -- in favour of the later period.
///
/// Assumes times are normalized to the same day, i.e. 4am tomorrow is actually
/// "28 o'clock" today.
///
/// Returns ranges normalized the same way.
///
/// Throws an [ArgumentError] if [timesOfDay] is empty.
TimeRange _mostPopularFiveHourWindow(Iterable<TimeOfDay> timesOfDay,
    {required bool earlierIsBetter}) {
  if (timesOfDay.isEmpty)
    throw ArgumentError('_mostPopularFiveHourWindow called with an empty list');

  final list = timesOfDay.toList();
  list.sort((a, b) => (a.hours - b.hours) * 60 + a.minutes - b.minutes);
  var bestI = 0, bestJ = 0, bestCount = 0;
  for (int i = 0, j = 0; i < list.length; ++i) {
    while (_isMoreThanFiveHoursLater(list[i], list[j])) ++j;
    final count = i - j + 1;
    if (count > bestCount || !earlierIsBetter && count == bestCount) {
      bestCount = count;
      bestI = i;
      bestJ = j;
    }
  }
  return TimeRange(list[bestJ], list[bestI]);
}

/// Whether [laterTime] is more than five hours later than [earlierTime].
bool _isMoreThanFiveHoursLater(TimeOfDay laterTime, TimeOfDay earlierTime) {
  return (laterTime - earlierTime).inMinutes > 5 * 60;
}

bool _inTheSameDay(Record a, Record b) {
  // Normalize to 4AM day divider. See other comments in file.
  final offsetA = a.time.subtract(Duration(hours: 4));
  final offsetB = b.time.subtract(Duration(hours: 4));
  return offsetA.year == offsetB.year &&
      offsetA.month == offsetB.month &&
      offsetA.day == offsetB.day;
}

class NotEnoughDataException implements Exception {
  final String message;

  NotEnoughDataException(this.message);

  @override
  String toString() {
    return 'NotEnoughDataException: $message';
  }
}