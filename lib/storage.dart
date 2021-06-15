/// Stores and loads records from disk, cache (future), cloud (future).
import 'dart:async';
import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

import 'message_and_cause_throwable.dart';
import 'time_formatting.dart';
import 'record.dart';

class Storage {
  /// The path to the internal file where the records are stored.
  Future<String> get _recordsFilePath async {
    final documentsDirectory = (await getApplicationDocumentsDirectory()).path;
    return '$documentsDirectory/records.csv';
  }

  /// The internal file where the records are stored.
  Future<File> get _recordsFile async => File(await _recordsFilePath);

  /// Loads the records from the internal file.
  ///
  /// Throws a [LoadingRecordsFailedError] (an programming error) if:
  ///  * the internal file could not be read; or
  ///  * the internal file could not be parsed.
  Future<List<Record>> loadRecords() async {
    final filePath = await _recordsFilePath;

    try {
      final file = File(filePath);
      // The case during first use: there is no internal file yet.
      if (!await file.exists()) return [];

      final lines = await file.readAsLines();
      final result = _parseRecords(lines).toList();
      return result;
    } catch (e) {
      throw LoadingRecordsFailedError(cause: e);
    }
  }

  /// Stores the given records to the internal file, overwriting the existing
  /// contents.
  Future<void> storeRecords(List<Record> records) async {
    final file = await _recordsFile;
    await file.writeAsString(_serializeRecords(records).join('\n'));
  }

  Future<void> storeSingleRecord(Record record) async {
    final file = await _recordsFile;
    await file.writeAsString(
      '\n${_serializeSingleRecord(record)}',
      mode: FileMode.append,
    );
  }

  /// Deletes all records from the internal file that match [record].
  Future<void> deleteSingleRecord(Record record) async {
    final records = await loadRecords();
    await storeRecords(records.where((r) => r != record).toList());
  }

  /// Opens a dialog and exports the stored records to a file.
  ///
  /// Throws a [ExportRecordsFailedException] if there as a problem exporting the
  /// file (possibly a user error).
  Future<void> exportRecords() async {
    final params = SaveFileDialogParams(
      sourceFilePath: await _recordsFilePath,
      fileName: 'weight_records.csv',
    );
    try {
      // If the result is null the operation was canceled, but do we care?
      await FlutterFileDialog.saveFile(params: params);
    } catch (e) {
      throw ExportRecordsFailedException(cause: e);
    }
  }

  /// Opens a dialog and imports records from a file to the storage.
  ///
  /// Returns whether the records have been imported or the operation was aborted
  /// by the user (when the result is false).
  ///
  /// Throws a [ImportingRecordsFailedException] in case of failure (possibly a
  /// user error).
  Future<bool> importRecords() async {
    final params = OpenFileDialogParams(
        dialogType: OpenFileDialogType.document,
        sourceType: SourceType.photoLibrary);
    try {
      // Can throw for undocumented reasons.
      final filePath = await FlutterFileDialog.pickFile(params: params);
      if (filePath == null) {
        // The user didn't pick a file: abort, don't throw.
        return false;
      }
      final file = File(filePath);
      if (!await file.exists())
        throw ImportingRecordsFailedException(
            message: 'File "$filePath" does not exist.');

      // Can throw for undocumented reasons, but possibly same as
      // [File.readAsLinesSync].
      final lines = await file.readAsLines();

      // Try to parse records; will throw on error.
      _parseRecords(lines).toList();

      // Can throw if [_recordsFilePath] is a directory.
      await File(filePath).copy(await _recordsFilePath);

      return true;
    } catch (e) {
      throw ImportingRecordsFailedException(cause: e);
    }
  }

  /// Parses records from the lines of a .csv file.
  ///
  /// Throws an error if parsing failed, i.e. the format was invalid.
  ///
  /// The format of a line is as follows:
  ///
  /// 2021-05-09 08:30,79.5
  ///
  /// that is: <DateTime>,<WeightInKg>.
  Iterable<Record> _parseRecords(List<String> lines) =>
      lines.where((l) => l.isNotEmpty).map(_parseSingleRecord);

  Record _parseSingleRecord(String line) {
    final parts = _splitDateTimeAndWeight(line);
    final dateTimeParts = _splitDateAndTime(parts[0], line);

    final date = DateTime.parse(dateTimeParts[0]);
    final time = _parseTime(dateTimeParts[1], line);

    final weight = num.parse(parts[1]);
    return Record(
        weight,
        DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
  }

  /// Serializes records as lines of a .csv file.
  Iterable<String> _serializeRecords(List<Record> records) =>
      records.map(_serializeSingleRecord);

  String _serializeSingleRecord(Record record) {
    final date = formatDate(record.time);
    final time = formatEnteredTime(record.time);
    final weight = record.weight;

    final result = '$date $time,$weight';
    print(result);
    return result;
  }

  List<String> _splitDateTimeAndWeight(String line) {
    final parts = line.split(',');
    if (parts.length != 2) {
      throw 'Parsing failed: parts.length is ${parts.length}, rather than 2 for'
          ' line "$line".';
    }
    return parts;
  }

  List<String> _splitDateAndTime(String dateTime, String line) {
    final dateTimeParts = dateTime.split(' ');
    if (dateTimeParts.length != 2) {
      throw 'Parsing failed: dateTimeParts.length is ${dateTimeParts.length}, '
          'rather than 2 for line "$line".';
    }
    return dateTimeParts;
  }

  DateTime _parseTime(String timeString, String line) {
    final time = tryParseEnteredTime(timeString);
    if (time == null) {
      throw 'Parsing failed: could not parse time $timeString for line $line';
    }
    return time;
  }
}

// Custom errors and exceptions.

class LoadingRecordsFailedError extends MessageAndCauseThrowable {
  LoadingRecordsFailedError({String? message, dynamic cause})
      : super(message: message, cause: cause) ;
}

class ExportRecordsFailedException extends MessageAndCauseThrowable {
  ExportRecordsFailedException({String? message, dynamic cause})
      : super(message: message, cause: cause);
}

class ImportingRecordsFailedException extends MessageAndCauseThrowable {
  ImportingRecordsFailedException({String? message, dynamic cause})
      : super(message: message, cause: cause);
}
