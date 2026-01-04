import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:voice_notes/core/packages/bloc/bloc_observer.dart';
import 'package:voice_notes/core/packages/di/app_initializer.dart';

void main() {
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = BlocsObserver();
    initializeDateFormatting();

    runApp(const AppInitializer());
  }, (e, s) => print('MAIN: $e\n$s'));
}
