import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/feature/data/local/data_sources/folder_local_data_source.dart';
import 'package:voice_notes/feature/data/local/data_sources/note_audio_local_data_source.dart';
import 'package:voice_notes/feature/data/local/mappers/folder_mapper.dart';
import 'package:voice_notes/feature/data/local/mappers/note_mapper.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_stats.dart';
import 'package:voice_notes/feature/domain/entities/storage_overview_stats.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';

/// Репозиторий статистики и управления аудиохранилищем.
@Singleton(as: StorageStatsRepository)
class StorageStatsRepositoryImpl implements StorageStatsRepository {
  final NoteAudioLocalDataSource _audioDataSource;
  final FolderLocalDataSource _folderDataSource;

  StorageStatsRepositoryImpl(this._audioDataSource, this._folderDataSource);

  // ─────────────────────────────────────────────────────────────
  // Overview
  // ─────────────────────────────────────────────────────────────

  @override
  Future<StorageOverviewStats> getOverview() async {
    final audios = await _audioDataSource.getAll();
    return _aggregateOverview(audios);
  }

  @override
  Stream<StorageOverviewStats> watchOverview() {
    return _audioDataSource.watchAll().map(_aggregateOverview);
  }

  StorageOverviewStats _aggregateOverview(List<NoteAudioObject> audios) {
    if (audios.isEmpty) return const StorageOverviewStats.empty();

    int bytes = 0;
    for (final a in audios) {
      bytes += a.sizeBytes;
    }

    return StorageOverviewStats(totalBytes: bytes, totalCount: audios.length);
  }

  // ─────────────────────────────────────────────────────────────
  // Folder stats
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<FolderStorageStats>> getFolderStats() async {
    final audios = await _audioDataSource.getAll();
    final folders = await _folderDataSource.getAll();
    return _aggregateFolderStats(audios, folders);
  }

  @override
  Stream<List<FolderStorageStats>> watchFolderStats() {
    return Rx.combineLatest2(
      _audioDataSource.watchAll(),
      _folderDataSource.watchAll(),
      _aggregateFolderStats,
    );
  }

  List<FolderStorageStats> _aggregateFolderStats(
    List<NoteAudioObject> audios,
    List<FolderObject> folders,
  ) {
    final grouped = <String?, List<NoteAudioObject>>{};
    for (final a in audios) {
      grouped.putIfAbsent(a.folderUid, () => []).add(a);
    }

    final foldersByUid = <String, FolderObject>{
      for (final f in folders) f.uid: f,
    };

    final result = <FolderStorageStats>[];
    grouped.forEach((folderUid, items) {
      int bytes = 0;
      int durationMs = 0;
      for (final a in items) {
        bytes += a.sizeBytes;
        durationMs += a.durationMs;
      }

      final folderObj = folderUid != null ? foldersByUid[folderUid] : null;
      result.add(
        FolderStorageStats(
          folder: folderObj != null ? FolderMapper.toDomain(folderObj) : null,
          bytes: bytes,
          count: items.length,
          totalDuration: Duration(milliseconds: durationMs),
        ),
      );
    });

    result.sort((a, b) => b.bytes.compareTo(a.bytes));
    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // Folder detail
  // ─────────────────────────────────────────────────────────────

  @override
  Future<({FolderEntity? folder, List<NoteAudioStats> notes})> getFolderDetail(
    String? folderUid,
  ) async {
    final pairs = await _audioDataSource.getFolderNotePairs(folderUid);
    final notes = [
      for (final (audio, note) in pairs)
        NoteAudioStats(
          note: NoteMapper.toDomain(note),
          bytes: audio.sizeBytes,
          duration: Duration(milliseconds: audio.durationMs),
        ),
    ];

    FolderEntity? folder;
    if (folderUid != null) {
      try {
        final folderObj = await _folderDataSource.getByUid(folderUid);
        folder = FolderMapper.toDomain(folderObj);
      } catch (_) {
        // Папка удалена между навигацией и загрузкой — показываем без имени.
      }
    }

    return (folder: folder, notes: notes);
  }

  // ─────────────────────────────────────────────────────────────
  // Delete operations
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> deleteNoteAudio(String noteUid) async {
    final path = await _audioDataSource.deleteNoteAudio(noteUid);
    if (path != null) await AudioPaths.deleteFile(path);
  }

  @override
  Future<void> deleteFolderAudio(String? folderUid) async {
    final paths = await _audioDataSource.deleteFolderAudio(folderUid);
    await Future.wait([for (final path in paths) AudioPaths.deleteFile(path)]);
  }

  @override
  Future<void> deleteAllAudio() async {
    final paths = await _audioDataSource.deleteAllAudio();
    await Future.wait([for (final path in paths) AudioPaths.deleteFile(path)]);
  }
}
