import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/bloc/bloc_observer.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/theme/app_theme.dart';

/// Provides access to the ObjectBox Store throughout the app.
late DatabaseClient objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = BlocsObserver();
  objectbox = await ObjectBoxDatabase.create();
  await DownloadManager.instance.init();

  final appRouter = AppRouter.createRouter();

  runApp(MyApp(router: appRouter));
}

class MyApp extends StatelessWidget {
  final GoRouter router;

  const MyApp({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Voice Notes',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
