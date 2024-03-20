import 'package:flutter/material.dart';
import 'package:t700kilos/storage.dart';
import 'package:t700kilos/ui/app.dart';
import 'package:t700kilos/util/clock.dart';
import 'package:t700kilos/util/decimal_number_formatter.dart';
import 'package:t700kilos/util/time_formatting.dart';
import 'package:t700kilos/record.dart';

/// Full-screen widget that allows the entry of new weight measurement.
class NewEntryWidget extends StatefulWidget {
  final T700KilosApp app;
  final Storage storage;
  final Clock clock;

  /// Whether this widget is the one at startup, or one created later.
  final bool isFirst;

  NewEntryWidget({
    required this.app,
    required this.storage,
    required this.clock,
    required this.isFirst,
  });

  @override
  _NewEntryWidgetState createState() => _NewEntryWidgetState();
}

class _NewEntryWidgetState extends State<NewEntryWidget> {
  num _enteredWeight = 0.0;
  late DateTime _enteredTime = widget.clock.now;
  bool _hasSuccessfullyEnteredTime = false;

  bool isEntryPositive() => _enteredWeight > 0;

  @override
  Widget build(BuildContext context) {
    final bigText = Theme.of(context).textTheme.displayLarge;
    final smallText = Theme.of(context).textTheme.headlineMedium;

    final timeController =
        TextEditingController(text: formatEnteredTime(_enteredTime));

    return GestureDetector(
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
          backgroundColor: widget.app.colorScheme.primary,
        ),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Opa!', style: bigText),
          Text('Enter weight:', style: smallText),
          ListTile(
              title: TextField(
                key: Key("weight input"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                inputFormatters: [DecimalNumberFormatter()],
                onChanged: (value) {
                  final weight = (value != '') ? num.parse(value) : 0.0;
                  setState(() {
                    _enteredWeight = weight;
                  });
                },
                style: smallText,
              ),
              trailing: Text('kg', style: smallText)),
          Text('at time:', style: smallText),
          TextField(
              controller: timeController,
              keyboardType: TextInputType.text,
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
        floatingActionButton: isEntryPositive()
            ? FloatingActionButton(
                child: Icon(Icons.check),
                tooltip: 'Submit',
                onPressed: () async => await _pushSubmit(timeController.text),
                disabledElevation: 0,
                backgroundColor: widget.app.colorScheme.primary)
            : null,
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
