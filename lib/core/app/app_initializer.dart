import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easy_dialogs/flutter_easy_dialogs.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/di/di.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/error/initialization_error_screen.dart';
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
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class VoiceNotesApp extends StatelessWidget {
  final GoRouter router;

  const VoiceNotesApp({required this.router, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocaleCubit(prefs: getIt<SharedPreferences>()),
        ),
        BlocProvider(
          create: (_) => ThemeCubit(prefs: getIt<SharedPreferences>()),
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
              routerConfig: router,
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
