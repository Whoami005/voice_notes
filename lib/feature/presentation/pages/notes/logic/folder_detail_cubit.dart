import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/common/utils/date_grouper.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/Initializable_cubit.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'folder_detail_state.dart';

class FolderDetailCubit extends RefreshableCubit<FolderDetailData> {
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
    emitLoading();

    _subscription =
        Rx.combineLatest2<FolderEntity, List<NoteEntity>, FolderDetailData>(
          _folderRepository.watchByUid(folderId).whereType<FolderEntity>(),
          _noteRepository.watchByFolderId(folderId),
          (folder, notes) => FolderDetailData(folder: folder, notes: notes),
        ).listen(
          emitSuccess,
          onError: (Object e, StackTrace s) => emitError(AppFailure.from(e, s)),
          cancelOnError: false,
        );
  }

  @override
  Future<void> refresh() async {
    await execute(
      action: () async {
        final folder = await _folderRepository.getByUid(folderId);
        final notes = await _noteRepository.getByFolderId(folderId);

        emitSuccess(FolderDetailData(folder: folder!, notes: notes));
      },
    );
  }

  Future<void> deleteNote(String noteUid) async {
    await execute(action: () => _noteRepository.delete(noteUid));
  }

  Future<void> deleteFolder() async {
    await execute(action: () => _folderRepository.deleteWithNotes(folderId));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
