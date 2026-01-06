import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:voice_notes/core/app/app_initializer.dart';
import 'package:voice_notes/core/packages/bloc/bloc_observer.dart';

void main() {
  runZonedGuarded<void>(() {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = BlocsObserver();
    initializeDateFormatting();

    runApp(const AppInitializer());
  }, (e, s) => print('MAIN: $e\n$s'));
}
