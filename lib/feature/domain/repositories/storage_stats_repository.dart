import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_stats.dart';
import 'package:voice_notes/feature/domain/entities/storage_overview_stats.dart';

/// Репозиторий для работы со статистикой и управлением аудиохранилищем.
///
/// Работает в разрезе аудио, а не заметок: агрегирует по папкам и умеет
/// удалять только аудио (заметка и её транскрипт при этом сохраняются).
abstract interface class StorageStatsRepository {
  /// Реактивный поток общей статистики. Эмитит новое значение при любом
  /// изменении аудио (добавление/удаление/обновление).
  Stream<StorageOverviewStats> watchOverview();

  /// Текущий снимок общей статистики.
  Future<StorageOverviewStats> getOverview();

  /// Список папок с привязанной статистикой, отсортированный по убыванию
  /// размера. Папки без аудио не включаются.
  Future<List<FolderStorageStats>> getFolderStats();

  /// Реактивный поток статистики по папкам.
  Stream<List<FolderStorageStats>> watchFolderStats();

  /// Детальная информация по одной папке: entity самой папки + список записей
  /// с аудио, отсортированный по убыванию размера файла.
  Future<({FolderEntity? folder, List<NoteAudioStats> notes})> getFolderDetail(
    String? folderUid,
  );

  /// Удалить аудиофайл конкретной заметки (заметка остаётся).
  Future<void> deleteNoteAudio(String noteUid);

  /// Удалить аудио всех заметок в указанной папке (null — без папки).
  /// Заметки остаются, транскрипты сохраняются.
  Future<void> deleteFolderAudio(String? folderUid);

  /// Удалить аудио всех заметок в приложении. Все заметки и транскрипты
  /// остаются.
  Future<void> deleteAllAudio();
}
