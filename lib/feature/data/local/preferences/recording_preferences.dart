import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки, связанные с процессом записи аудио.
@singleton
class RecordingPreferences {
  final SharedPreferences _prefs;

  /// Сохранять оригинальные аудиозаписи после транскрибации.
  ///
  /// По умолчанию `true` — плеер работает из коробки для всех новых заметок.
  /// Пользователь может выключить ради экономии дискового пространства;
  /// изменение влияет только на будущие записи, существующие остаются.
  static const String _keyKeepOriginals = 'recording.keep_originals';

  RecordingPreferences(this._prefs);

  bool get keepOriginals => _prefs.getBool(_keyKeepOriginals) ?? true;

  Future<void> setKeepOriginals(bool value) {
    return _prefs.setBool(_keyKeepOriginals, value);
  }
}
