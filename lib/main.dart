import 'package:flutter/material.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Notes',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const FoldersScreen(),
    );
  }
}
