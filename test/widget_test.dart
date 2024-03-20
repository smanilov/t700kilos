import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:t700kilos/ui/app.dart';
import 'package:t700kilos/util/morning_evening_analysis.dart';
import 'package:t700kilos/storage.dart';
import 'package:t700kilos/util/clock.dart';
import 'package:t700kilos/record.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([Clock, Storage, MorningEveningAnalyser])
void main() {
  T700KilosApp buildTestApp() {
    final storage = MockStorage();
    final clock = MockClock();
    final analyser = MockMorningEveningAnalyser();

    when(clock.now).thenReturn(DateTime(1337));

    return T700KilosApp(storage, clock, analyser);
  }

  testWidgets('Submitting a record stores it', (WidgetTester tester) async {
    final storage = MockStorage();
    final clock = MockClock();
    final analyser = MockMorningEveningAnalyser();

    when(clock.now).thenReturn(DateTime(1337));

    // Build our app and trigger a frame.
    await tester.pumpWidget(T700KilosApp(storage, clock, analyser));

    // Verify that our welcome text is there.
    expect(find.text('Opa!'), findsOneWidget);

    // Enter some valid weight.
    await tester.enterText(find.byKey(Key("weight input")), "75.5");

    // Trigger state update: button is enabled only after valid text is entered.
    // Settle is needed, because the button appears with an animation.
    await tester.pumpAndSettle();

    // Tap the 'v' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify that a record has been stored.
    verify(storage.storeSingleRecord(Record(75.5, DateTime(1337))));

    // Verify that the confirmation text is there.
    expect(find.text('got it'), findsOneWidget);
  });

  testWidgets('Submitting is disabled initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildTestApp());

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Submitting is enabled when weight is entered',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildTestApp());

    // Enter some valid weight.
    await tester.enterText(find.byKey(Key("weight input")), "75.5");

    // Trigger state update.
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Submitting is disabled when weight is cleared',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildTestApp());

    // Enter some valid weight.
    await tester.enterText(find.byKey(Key("weight input")), "75.5");

    // Trigger state update.
    await tester.pump();

    // Clear weight.
    await tester.enterText(find.byKey(Key("weight input")), "");

    // Trigger state update.
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Submitting is disabled when zero weight is entered',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildTestApp());

    // Enter some valid weight.
    await tester.enterText(find.byKey(Key("weight input")), "0");

    // Trigger state update.
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Submitting is enabled for unreasonably high weights',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(buildTestApp());

    // Enter some valid weight.
    await tester.enterText(find.byKey(Key("weight input")), "700");

    // Trigger state update.
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
