import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/status/initializable_status_cubits.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_stats.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';

part 'folder_storage_state.dart';

/// Cubit детального экрана хранилища (список записей одной папки).
class FolderStorageCubit extends InitializableStatusCubit<FolderStorageState> {
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
  Future<void> refresh() async {
    try {
      emitSuccess(await _fetchDetail());
    } catch (e, s) {
      handleEffectError(e, s);
    }
  }

  Future<FolderStorageState> _fetchDetail() async {
    final detail = await _repository.getFolderDetail(folderUid);

    return state.copyWith(folder: detail.folder, notes: detail.notes);
  }

  Future<bool> deleteNoteAudio(String noteUid) async {
    try {
      await _repository.deleteNoteAudio(noteUid);

      emitSuccess(
        state.copyWith(
          notes: [
            for (final item in state.notes)
              if (item.note.uuid != noteUid) item,
          ],
        ),
      );

      return true;
    } catch (e, s) {
      handleEffectError(e, s);
      return false;
    }
  }

  Future<void> deleteAllInFolder() async {
    try {
      await _repository.deleteFolderAudio(folderUid);
      emitSuccess(state.copyWith(notes: const []));
    } catch (e, s) {
      handleEffectError(e, s);
    }
  }
}
