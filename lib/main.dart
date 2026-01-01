import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/asr/sherpa_asr_service.dart';
import 'package:voice_notes/core/packages/bloc/bloc_observer.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/data/local/data_sources/model_local_data_source.dart';
import 'package:voice_notes/feature/data/repositories/model_repository_impl.dart';

/// Provides access to the ObjectBox Store throughout the app.
late DatabaseClient objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = BlocsObserver();
  objectbox = await ObjectBoxDatabase.create();
  await DownloadManager.instance.init();
  // await AsrModelPaths.ensureDirectoriesExist();

  // Инициализируем ASR с выбранной моделью (если есть)
  await _initializeAsrService();

  final appRouter = AppRouter.createRouter();

  runApp(MyApp(router: appRouter));
}

///TODO: после убрать
/// Инициализирует ASR сервис с ранее выбранной моделью при старте приложения
Future<void> _initializeAsrService() async {
  try {
    final dataSource = ModelLocalDataSourceImpl(objectbox);
    final repository = ModelRepositoryImpl(
      localDataSource: dataSource,
      downloadManager: DownloadManager.instance,
    );

    final selectedModel = await repository.getSelectedModel();
    if (selectedModel == null) return;

    final modelPath = await repository.getModelPath(selectedModel.id);
    if (modelPath == null) return;

    await SherpaAsrService.instance.initialize(selectedModel, modelPath);
  } catch (e, s) {
    debugPrint('Failed to initialize ASR: $e $s');
  }
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
