import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({required this.locale});

  @override
  List<Object?> get props => [locale];
}

class LocaleCubit extends BaseCubit<LocaleState> {
  final SharedPreferences _prefs;

  static const _key = 'app_locale';

  static const List<Locale> _supportedCodes = AppLocalizations.supportedLocales;

  static String get systemCode =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  LocaleCubit({required SharedPreferences prefs})
    : _prefs = prefs,
      super(LocaleState(locale: readLocale(prefs)));

  static String get prefsKey => _key;

  static Locale readLocale(SharedPreferences prefs) {
    final code = prefs.getString(_key);

    if (code != null) {
      final isSupported = _supportedCodes.any((l) => l.languageCode == code);
      if (isSupported) return Locale(code);
    }

    final isSupported = _supportedCodes.any(
      (l) => l.languageCode == systemCode,
    );

    return isSupported ? Locale(systemCode) : const Locale('en');
  }

  Future<bool> setLocale(Locale locale) async {
    try {
      await _prefs.setString(_key, locale.languageCode);
      emit(LocaleState(locale: locale));
      return true;
    } catch (e, s) {
      logError(e, s);
      return false;
    }
  }
}
