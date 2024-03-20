import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t700kilos/util/morning_evening_analysis.dart';

import 'util/clock.dart';
import 'storage.dart';

import 'ui/app.dart';

Future<void> main() async {
  await forcePortraitOnlyForAndroid();

  runApp(T700KilosApp(
    new Storage(),
    new Clock(),
    new MorningEveningAnalyser(),
  ));
}

Future<void> forcePortraitOnlyForAndroid() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}