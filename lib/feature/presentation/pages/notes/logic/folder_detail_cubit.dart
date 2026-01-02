import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/common/utils/date_grouper.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'folder_detail_state.dart';

class FolderDetailCubit extends BaseCubit<FolderDetailData>
    implements Initializable {
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
        Rx.combineLatest2<FolderEntity?, List<NoteEntity>, FolderDetailData>(
          _folderRepository.watchByUid(folderId),
          _noteRepository.watchByFolderId(folderId),
          (FolderEntity? folder, List<NoteEntity> notes) =>
              FolderDetailData(folder: folder, notes: notes),
        ).listen(
          (FolderDetailData data) {
            if (data.folder == null) return;
            emitSuccess(data);
          },
          onError: (Object e, StackTrace s) => emitError(AppFailure.from(e, s)),
          cancelOnError: false,
        );
  }

  Future<void> deleteNote(String noteUid) async {
    await safeExecute(action: () => _noteRepository.delete(noteUid));
  }

  Future<void> deleteFolder() async {
    await safeExecute(
      action: () => _folderRepository.deleteWithNotes(folderId),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
