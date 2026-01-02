import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/di/app_initialization_result.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/pages/error/initialization_error_screen.dart';

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
    return MaterialApp.router(
      title: 'Voice Notes',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
