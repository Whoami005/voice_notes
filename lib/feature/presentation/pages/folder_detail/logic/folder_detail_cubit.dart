import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/common/utils/date_grouper.dart';
import 'package:voice_notes/core/state/async/initializable_async_cubits.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'folder_detail_state.dart';

class FolderDetailCubit extends InitializableAsyncCubit<FolderDetailData> {
  final NoteRepository _noteRepository;
  final FolderRepository _folderRepository;
  final String folderId;

  StreamSubscription<FolderDetailData>? _subscription;

  FolderDetailCubit({
    required NoteRepository noteRepository,
    required FolderRepository folderRepository,
    required this.folderId,
  }) : _noteRepository = noteRepository,
       _folderRepository = folderRepository;

  @override
  Future<void> init() async {
    try {
      emitLoading();
      if (isClosed) return;

      _subscription ??=
          Rx.combineLatest2<FolderEntity, List<NoteEntity>, FolderDetailData>(
            _folderRepository.watchByUid(folderId).whereType<FolderEntity>(),
            _noteRepository.watchByFolderId(folderId),
            (folder, notes) => FolderDetailData(folder: folder, notes: notes),
          ).listen(emitSuccess, onError: logError, cancelOnError: false);
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
  }

  @override
  Future<void> refresh() async {
    try {
      final folder = await _folderRepository.getByUid(folderId);
      final notes = await _noteRepository.getByFolderId(folderId);

      emitSuccess(FolderDetailData(folder: folder, notes: notes));
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
    }
  }

  Future<void> deleteNote(String noteUid) => guardAction((_) async {
    await _noteRepository.delete(noteUid);
  });

  Future<bool> deleteFolder() async {
    try {
      await _folderRepository.deleteWithNotes(folderId);

      return true;
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
      return false;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
