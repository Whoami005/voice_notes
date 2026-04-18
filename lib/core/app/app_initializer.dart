import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_dialogs/flutter_easy_dialogs.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/di/di.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/presentation/pages/error/initialization_error_screen.dart';
import 'package:voice_notes/feature/presentation/pages/transcription/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<AppInitializationResult> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = configureDependencies();
  }

  void _retry() {
    setState(() {
      _initFuture = configureDependencies(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitializationResult>(
      future: _initFuture,
      builder: (context, snapshot) {
        final isDone = snapshot.connectionState != ConnectionState.done;
        if (isDone) return const _SplashScreen();

        return switch (snapshot.data) {
          AppInitializationSuccess() => VoiceNotesApp(
            router: getIt<AppRouter>().router,
          ),
          AppInitializationFailure(:final error) => InitializationErrorScreen(
            error: error,
            onRetry: _retry,
          ),
          null => const _SplashScreen(),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: context.mediaQuery.copyWith(
        boldText: false,
        textScaler: TextScaler.noScaling,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Voice Notes',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

/// Транслирует lifecycle-события (resume) в [TranscriptionQueueCubit], чтобы
/// не обращаться к сервисам напрямую.
class VoiceNotesApp extends StatefulWidget {
  final GoRouter router;

  const VoiceNotesApp({required this.router, super.key});

  @override
  State<VoiceNotesApp> createState() => _VoiceNotesAppState();
}

class _VoiceNotesAppState extends State<VoiceNotesApp>
    with WidgetsBindingObserver {
  late TranscriptionQueueCubit _queueCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueCubit = TranscriptionQueueCubit(
      service: getIt<TranscriptionQueueService>(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _queueCubit.onResume();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => LocaleCubit(prefs: getIt<SharedPreferences>()),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => ThemeCubit(prefs: getIt<SharedPreferences>()),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => AsrCubit(
            asrService: getIt<AsrService>(),
            modelRepository: getIt<ModelRepository>(),
          ),
        ),
        BlocProvider<TranscriptionQueueCubit>(
          lazy: false,
          create: (_) => _queueCubit,
        ),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.select((ThemeCubit cubit) => cubit.state.mode);
          final locale = context.select(
            (LocaleCubit cubit) => cubit.state.locale,
          );

          return MediaQuery(
            data: context.mediaQuery.copyWith(
              boldText: false,
              textScaler: TextScaler.noScaling,
            ),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Voice Notes',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: theme.themeMode,
              routerConfig: widget.router,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: FlutterEasyDialogs.builder(),
            ),
          );
        },
      ),
    );
  }
}
