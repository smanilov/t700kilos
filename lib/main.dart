import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t700kilos/morning_evening_analysis.dart';

import 'clock.dart';
import 'decimal_number_formatter.dart';
import 'ordinal.dart';
import 'time_formatting.dart';
import 'record.dart';
import 'storage.dart';

Future<void> main() async {
  await forcePortraitOnlyForAndroid();

  runApp(T700KilosApp(
    new Storage(),
    new Clock(),
    new MorningEveningAnalyser(),
    new SwipeAnalyser(),
  ));
}

Future<void> forcePortraitOnlyForAndroid() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class SwipeAnalyser {
  final panHistory = <DragUpdateDetails>[];

  void recordPan(DragUpdateDetails details) {
    panHistory.add(details);
  }

  bool hasSwipedLeft() {
    // TODO: be smarter
    return panHistory.isNotEmpty && panHistory.last.delta.dx < 0;
  }

  bool hasSwipedRight() {
    // TODO: be smarter
    return panHistory.isNotEmpty && panHistory.last.delta.dx > 0;
  }
}

enum SlideDirection {
  left,
  right,
}

class T700KilosApp extends StatelessWidget {
  final Storage storage;
  final Clock clock;
  final MorningEveningAnalyser morningEveningAnalyser;
  final SwipeAnalyser swipeAnalyser;

  T700KilosApp(
    this.storage,
    this.clock,
    this.morningEveningAnalyser,
    this.swipeAnalyser,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '700 kilos',
      theme: ThemeData(
        primaryColor: Colors.yellow,
        accentColor: Colors.yellow,
      ),
      home: createWelcomeWidget(),
    );
  }

  NewEntryWidget createWelcomeWidget() => NewEntryWidget(
        app: this,
        storage: storage,
        clock: clock,
        swipeAnalyser: swipeAnalyser,
        isFirst: true,
      );

  /// Navigates to the "Show Saved" widget, after poping all the widgets off the
  /// navigation stack.
  Future<void> navigateToShowSaved(BuildContext context,
      [SlideDirection? slideDirection]) async {
    try {
      final records = await storage.loadRecords();
      // Remove all items on the [Navigator]'s stack and push "Show Saved".
      await Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return ShowSavedWidget(
                this, storage, clock, morningEveningAnalyser, records);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (slideDirection == null) {
              return child;
            }
            final slide = Tween(
                    begin: Offset(
                        slideDirection == SlideDirection.left ? -1.0 : 1.0,
                        0.0),
                    end: Offset.zero)
                .chain(CurveTween(curve: Curves.ease));

            return SlideTransition(
              position: animation.drive(slide),
              child: child,
            );
          },
        ),
        (_) => false, // No filter, i.e. remove all.
      );
    } on LoadingRecordsFailedError catch (e) {
      final message = 'Internal error: loading records failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message.')));
      print('$message: $e');
    }
  }

  /// Navigates to the "Confirmation" widget. Replaces the current widget in the
  /// navigator, as this is assumed to be invoked only by the "New Entry"
  /// widget.
  Future<void> navigateToConfirmationWidget(BuildContext context,
      {required num enteredWeight, required DateTime enteredTime}) async {
    // Replace new entry widget with confirmation widget.
    await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return ConfirmationWidget(this, enteredWeight, enteredTime);
    }));
  }

  /// Navigates to the "New Entry" widget by simply pushing it onto the
  /// [Navigator]'s stack.
  Future<void> navigateToNewEntry(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return NewEntryWidget(
        app: this,
        storage: storage,
        clock: clock,
        swipeAnalyser: swipeAnalyser,
        isFirst: false,
      );
    }));
  }
}

/// Full-screen widget that allows the entry of new weight measurement.
class NewEntryWidget extends StatefulWidget {
  final T700KilosApp app;
  final Storage storage;
  final Clock clock;
  final SwipeAnalyser swipeAnalyser;

  /// Whether this widget is the one at startup, or one created later.
  final bool isFirst;

  NewEntryWidget({
    required this.app,
    required this.storage,
    required this.clock,
    required this.swipeAnalyser,
    required this.isFirst,
  });

  @override
  _NewEntryWidgetState createState() => _NewEntryWidgetState();
}

class _NewEntryWidgetState extends State<NewEntryWidget> {
  num _enteredWeight = 0.0;
  late DateTime _enteredTime = widget.clock.now;
  bool _hasSuccessfullyEnteredTime = false;

  @override
  Widget build(BuildContext context) {
    final bigText = Theme.of(context).textTheme.headline1;
    final smallText = Theme.of(context).textTheme.headline4;

    final timeController =
        TextEditingController(text: formatEnteredTime(_enteredTime));

    return GestureDetector(
      onPanUpdate: (details) {
        widget.swipeAnalyser.recordPan(details);
        if (widget.isFirst) {
          if (widget.swipeAnalyser.hasSwipedLeft()) {
            widget.app.navigateToShowSaved(context, SlideDirection.right);
          }
        } else {
          if (widget.swipeAnalyser.hasSwipedRight()) {
            widget.app.navigateToShowSaved(context, SlideDirection.left);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('New Entry'),
          actions: widget.isFirst
              ? [
                  IconButton(
                    icon: Icon(Icons.list),
                    onPressed: () async =>
                        await widget.app.navigateToShowSaved(context),
                  ),
                ]
              : [],
        ),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Opa!', style: bigText),
          Text('Enter weight:', style: smallText),
          ListTile(
              title: TextField(
                key: Key("weight input"),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                inputFormatters: [DecimalNumberFormatter()],
                onChanged: (value) {
                  if (value != '') _enteredWeight = num.parse(value);
                },
                style: smallText,
              ),
              trailing: Text('kg', style: smallText)),
          Text('at time:', style: smallText),
          TextField(
              controller: timeController,
              keyboardType: TextInputType.datetime,
              textAlign: TextAlign.center,
              onTap: () {
                if (!_hasSuccessfullyEnteredTime) {
                  // Delete the default entry on first tap.
                  timeController.text = '';
                }
              },
              onSubmitted: (String value) {
                final enteredTime =
                    tryParseEnteredTime(value, now: widget.clock.now);
                if (enteredTime != null) {
                  _enteredTime = enteredTime;
                  _hasSuccessfullyEnteredTime = true;
                } else {
                  // Restore last successful entered time if parsing failed.
                  timeController.text = formatEnteredTime(_enteredTime);
                }
              },
              style: smallText),
        ])),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.check),
            tooltip: 'Submit',
            onPressed: () async => await _pushSubmit(timeController.text)),
      ),
    );
  }

  // The [currentTimeString] needs to be passed, in case the user hasn't
  // submitted what they've been typing. This is not the case for the weight,
  // as it is saved on every entered character, but the entered time can be
  // intermittently incorrect.
  Future<void> _pushSubmit(String currentTimeString) async {
    _enteredTime =
        tryParseEnteredTime(currentTimeString, now: widget.clock.now) ??
            _enteredTime;
    await _storeWeightAndTime();

    await widget.app.navigateToConfirmationWidget(context,
        enteredWeight: _enteredWeight, enteredTime: _enteredTime);
  }

  Future<void> _storeWeightAndTime() async {
    // TODO: consider racing
    await widget.storage
        .storeSingleRecord(Record(_enteredWeight, _enteredTime));
  }
}

class ConfirmationWidget extends StatelessWidget {
  final T700KilosApp app;

  final num enteredWeight;
  final DateTime enteredDate;

  const ConfirmationWidget(this.app, this.enteredWeight, this.enteredDate);

  @override
  Widget build(BuildContext context) {
    final bigText = Theme.of(context).textTheme.headline1;
    final smallText = Theme.of(context).textTheme.headline4;

    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('got it', style: bigText),
          Text('${enteredWeight}kg at ${formatEnteredTime(enteredDate)}',
              style: smallText),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        child: Text('OK'),
        tooltip: 'OK',
        onPressed: () async => await app.navigateToShowSaved(context),
      ),
    );
  }
}

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
    widget.records.sort((a, b) => b.time.difference(a.time).inMinutes);

    final smallerText =
        Theme.of(context).textTheme.headline5 ?? TextStyle(fontSize: 24);

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
      ),
      body: ListView(children: divided),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'New entry',
        onPressed: () async => await widget.app.navigateToNewEntry(context),
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
  Widget _createDriveButton(
      {required IconData icon,
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
