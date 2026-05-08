import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';

enum AppThemeMode {
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    light => ThemeMode.light,
    dark => ThemeMode.dark,
  };

  static AppThemeMode? fromString(String key) => switch (key) {
    'light' => light,
    'dark' => dark,
    _ => null,
  };
}

class ThemeState extends Equatable {
  final AppThemeMode mode;

  const ThemeState({required this.mode});

  @override
  List<Object?> get props => [mode];
}

class ThemeCubit extends BaseCubit<ThemeState> {
  final SharedPreferences _prefs;

  static const _key = 'app_theme';

  ThemeCubit({required SharedPreferences prefs})
    : _prefs = prefs,
      super(ThemeState(mode: readMode(prefs)));

  static String get prefsKey => _key;

  static AppThemeMode readMode(SharedPreferences prefs) {
    final savedTheme = prefs.getString(_key);

    if (savedTheme != null) {
      final mode = AppThemeMode.fromString(savedTheme);
      if (mode != null) return mode;
    }

    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    return brightness == Brightness.light
        ? AppThemeMode.light
        : AppThemeMode.dark;
  }

  Future<bool> setTheme(AppThemeMode mode) async {
    try {
      await _prefs.setString(_key, mode.name);
      emit(ThemeState(mode: mode));

      return true;
    } catch (e, s) {
      logError(e, s);
      return false;
    }
  }
}
