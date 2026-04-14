import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/status/initializable_status_cubits.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_stats.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';

part 'folder_storage_state.dart';

/// Cubit детального экрана хранилища (список записей одной папки).
class FolderStorageCubit extends RefreshableStatusCubit<FolderStorageState> {
  final StorageStatsRepository _repository;
  final String? folderUid;

  FolderStorageCubit({
    required StorageStatsRepository repository,
    required this.folderUid,
  }) : _repository = repository,
       super(const FolderStorageState());

  bool get isEmptyFolder => folderUid == null;

  @override
  Future<void> init() => load(_fetchDetail);

  @override
  Future<void> refresh() => guard(_fetchDetail);

  Future<FolderStorageState> _fetchDetail() async {
    final detail = await _repository.getFolderDetail(folderUid);

    return state.copyWith(folder: detail.folder, notes: detail.notes);
  }

  Future<void> deleteNoteAudio(String noteUid) async {
    try {
      await _repository.deleteNoteAudio(noteUid);
      final detail = await _repository.getFolderDetail(folderUid);
      emitSuccess(state.copyWith(notes: detail.notes));
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> deleteAllInFolder() async {
    try {
      await _repository.deleteFolderAudio(folderUid);
      emitSuccess(state.copyWith(notes: const []));
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }
}
