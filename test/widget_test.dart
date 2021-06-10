import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:t700kilos/main.dart';
import 'package:t700kilos/morning_evening_analysis.dart';
import 'package:t700kilos/storage.dart';
import 'package:t700kilos/clock.dart';
import 'package:t700kilos/record.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([Clock, Storage, MorningEveningAnalyser])
void main() {
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

    // Tap the 'v' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    // Verify that a record has been stored.
    verify(storage.storeSingleRecord(Record(75.5, DateTime(1337))));

    // Unclear why this is necessary, but it is.
    await tester.pump();

    // Verify that the confirmation text is there.
    expect(find.text('got it'), findsOneWidget);
  });
}
