import 'package:flutter/material.dart';
import 'package:t700kilos/record.dart';
import 'package:t700kilos/storage.dart';
import 'package:t700kilos/ui/app.dart';
import 'package:t700kilos/util/clock.dart';
import 'package:t700kilos/util/morning_evening_analysis.dart';
import 'package:t700kilos/util/ordinal.dart';
import 'package:t700kilos/util/time_formatting.dart';

class ShowSavedWidget extends StatefulWidget {
  final T700KilosApp app;
  final Storage storage;
  final Clock clock;
  final MorningEveningAnalyser morningEveningAnalyser;

  final List<Record> records;

  ShowSavedWidget(this.app, this.storage, this.clock,
      this.morningEveningAnalyser, this.records);

  @override
  _ShowSavedWidgetState createState() => _ShowSavedWidgetState();
}

class _ShowSavedWidgetState extends State<ShowSavedWidget> {
  @override
  Widget build(BuildContext context) {
    // Make sure records are always sorted before displaying them.
    widget.records.sort((a, b) =>
    b.time
        .difference(a.time)
        .inMinutes);

    final smallerText =
        Theme
            .of(context)
            .textTheme
            .headlineSmall ?? TextStyle(fontSize: 24);

    final morningTextStyle = smallerText.copyWith();
    final eveningTextStyle = smallerText.copyWith();
    final otherTextStyle = smallerText.copyWith(color: Colors.grey);

    final morningEveningRecords = widget.morningEveningAnalyser
        .computeMorningEveningRecords(widget.records);
    final shouldDecorateMorningAndEvening = widget.records.length >= 10 &&
        morningEveningRecords.morningRecords.isNotEmpty &&
        morningEveningRecords.eveningRecords.isNotEmpty;

    final tiles = widget.records.map((Record record) {
      final weight = '${record.weight}';
      final time = '${formatEnteredTime(record.time)}';

      final dayDiff = _dayDifferenceFromNow(record.time, widget.clock.now);
      final day = dayDiff < 7
          ? threeLetterDayOfWeek(record.time.weekday)
          : '${ordinal(record.time.day)}';

      final monthDiff = _monthDifferenceFromNow(record.time, widget.clock.now);
      final month = threeLetterMonth(record.time.month);

      final year = record.time.year;

      final isMorningTime =
      morningEveningRecords.morningRecords.contains(record);
      final isEveningTime =
      morningEveningRecords.eveningRecords.contains(record);

      return Center(
        child: ListTile(
          title: Text(
            dayDiff == 0
                ? '${weight}kg at $time'
                : dayDiff == 1
                ? '${weight}kg at $time Yesterday'
                : monthDiff == 0 || dayDiff < 7
                ? '${weight}kg at $time on $day'
                : monthDiff < 12
                ? '${weight}kg at $time on $month $day'
                : '${weight}kg at $time on $month $day, $year',
            style: !shouldDecorateMorningAndEvening
                ? smallerText
                : (isMorningTime
                ? morningTextStyle
                : isEveningTime
                ? eveningTextStyle
                : otherTextStyle),
          ),
          tileColor: shouldDecorateMorningAndEvening && isEveningTime
              ? Colors.black12
              : null,
          onLongPress: () => _confirmRecordDeletion(context, record),
        ),
      );
    });

    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(context: context, tiles: tiles).toList()
        : <Widget>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Progression'),
        actions: [
          IconButton(
            icon: Icon(Icons.import_export),
            onPressed: _pushImportExport,
          ),
        ],
        backgroundColor: widget.app.colorScheme.primary,
      ),
      body: ListView(children: divided),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'New entry',
        onPressed: () async => await widget.app.navigateToNewEntry(context),
        backgroundColor: widget.app.colorScheme.primary,
      ),
    );
  }

  Future<void> _pushImportExport() async {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
              title: Center(child: Text("Manage records")),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _createDriveButton(
                        icon: Icons.upload_sharp,
                        text: "Export",
                        onPressed: () async {
                          Navigator.of(context).pop();
                          _pushExport();
                        }),
                    _createDriveButton(
                        icon: Icons.download_sharp,
                        text: "Import",
                        onPressed: () async {
                          Navigator.of(context).pop();
                          _pushImport();
                        }),
                  ],
                )
              ]);
        });
  }

  /// Creates a circular button with text, inspired by the Google Drive UI.
  Widget _createDriveButton({required IconData icon,
    required String text,
    required VoidCallback onPressed,
    Color? color}) {
    final lightGrey = Colors.black12;
    final grey = Colors.black54;
    return Padding(
        padding: EdgeInsets.all(6.0),
        child: TextButton(
          style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
          child: Column(children: [
            Ink(
              decoration: ShapeDecoration(
                  shape: CircleBorder(side: BorderSide(color: lightGrey))),
              child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(icon, color: color ?? grey)),
            ),
            Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(text, style: TextStyle(color: grey))),
          ]),
          onPressed: onPressed,
        ));
  }

  Future<void> _pushImport() async {
    try {
      if (await widget.storage.importRecords()) {
        // Reload records in case of success.
        final records = await widget.storage.loadRecords();
        setState(() {
          widget.records
            ..clear()
            ..addAll(records);
        });
      }
    } on ImportingRecordsFailedException catch (e) {
      final message = 'Importing records failed';
      final hint = 'is the file correct?';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message; $hint')));
      print('$message: $e');
    } on LoadingRecordsFailedError catch (e) {
      final message =
          'Internal error: loading records failed after successfully importing file';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message.')));
      print('$message: $e');
    }
  }

  Future<void> _pushExport() async {
    try {
      await widget.storage.exportRecords();
    } on ExportRecordsFailedException catch (e) {
      final message = 'Exporting records failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message.')));
      print('$message: $e');
    }
  }

  void _confirmRecordDeletion(BuildContext context, Record record) {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
              title: Center(child: Text("Confirm deletion?")),
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("Deleting a record cannot be undone."),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _createDriveButton(
                      icon: Icons.close,
                      text: "Cancel",
                      onPressed: () => Navigator.of(context).pop()),
                  _createDriveButton(
                      icon: Icons.delete,
                      text: "Delete",
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await widget.storage.deleteSingleRecord(record);
                        final records = await widget.storage.loadRecords();
                        setState(() {
                          widget.records
                            ..clear()
                            ..addAll(records);
                        });
                      },
                      color: Colors.red),
                ])
              ]);
        });
  }
}

/// Returns 0 if [time] is today, 1 if yesterday, and so on.
int _dayDifferenceFromNow(DateTime time, DateTime now) {
  final nowRoundedToDays = DateTime(now.year, now.month, now.day);
  final timeRoundedToDays = DateTime(time.year, time.month, time.day);
  final dayDiff = nowRoundedToDays.difference(timeRoundedToDays).inDays;

  return dayDiff;
}

/// Returns 0 if [time] is same month as today, 1 if last month, and so on.
int _monthDifferenceFromNow(DateTime time, DateTime now) {
  return (now.year - time.year) * 12 + (now.month - time.month);
}