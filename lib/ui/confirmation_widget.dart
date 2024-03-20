import 'package:flutter/material.dart';
import 'package:t700kilos/ui/app.dart';
import 'package:t700kilos/util/time_formatting.dart';

class ConfirmationWidget extends StatelessWidget {
  final T700KilosApp app;

  final num enteredWeight;
  final DateTime enteredDate;

  const ConfirmationWidget(this.app, this.enteredWeight, this.enteredDate);

  @override
  Widget build(BuildContext context) {
    final bigText = Theme.of(context).textTheme.displayLarge;
    final smallText = Theme.of(context).textTheme.headlineMedium;

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
          backgroundColor: app.colorScheme.primary),
    );
  }
}
