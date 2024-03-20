import 'package:flutter/material.dart';
import 'package:t700kilos/storage.dart';
import 'package:t700kilos/ui/confirmation_widget.dart';
import 'package:t700kilos/ui/show_saved_widget.dart';
import 'package:t700kilos/util/clock.dart';
import 'package:t700kilos/util/morning_evening_analysis.dart';

import 'new_entry_widget.dart';

class T700KilosApp extends StatelessWidget {
  final Storage storage;
  final Clock clock;
  final MorningEveningAnalyser morningEveningAnalyser;

  final ColorScheme colorScheme =
  ThemeData().colorScheme.copyWith(primary: Colors.yellow);

  T700KilosApp(this.storage, this.clock, this.morningEveningAnalyser);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData();
    return MaterialApp(
      title: '700 kilos',
      theme: theme.copyWith(colorScheme: colorScheme),
      home: createWelcomeWidget(),
    );
  }

  NewEntryWidget createWelcomeWidget() => NewEntryWidget(
    app: this,
    storage: storage,
    clock: clock,
    isFirst: true,
  );

  /// Navigates to the "Show Saved" widget, after popping all the widgets off
  /// the navigation stack.
  Future<void> navigateToShowSaved(BuildContext context) async {
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
              return child;
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
        isFirst: false,
      );
    }));
  }
}