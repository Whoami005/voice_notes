import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/core/state/status_state/status_cubit.dart';
import 'package:voice_notes/core/state/status_state/status_state.dart';

/// StatusCubit с автоматической инициализацией
///
/// Автоматически вызывает init() в конструкторе.
/// Используй когда нужна единоразовая инициализация.
///
/// Пример:
/// ```dart
/// class FoldersCubit extends InitializableStatusCubit<FoldersState> {
///   FoldersCubit(this._repository) : super(const FoldersState());
///
///   @override
///   Future<void> init() async {
///     await load(() async {
///       final folders = await _repository.getAll();
///       return state.copyWith(folders: folders);
///     });
///   }
/// }
/// ```
abstract class InitializableStatusCubit<T extends StatusState>
    extends StatusCubit<T>
    implements Initializable {
  InitializableStatusCubit(super.initialState) {
    _autoInit();
  }

  Future<void> _autoInit() async {
    try {
      await init();
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
  }
}

/// StatusCubit с автоматической инициализацией и refresh
///
/// Автоматически вызывает init() в конструкторе.
/// Поддерживает refresh() для pull-to-refresh паттерна.
///
/// Пример:
/// ```dart
/// class FoldersCubit extends RefreshableStatusCubit<FoldersState> {
///   FoldersCubit(this._repository) : super(const FoldersState());
///
///   @override
///   Future<void> init() async {
///     await load(() async {
///       final folders = await _repository.getAll();
///       return state.copyWith(folders: folders);
///     });
///   }
///
///   @override
///   Future<void> refresh() async {
///     await guard(() async {
///       final folders = await _repository.getAll();
///       return state.copyWith(folders: folders);
///     });
///   }
/// }
/// ```
abstract class RefreshableStatusCubit<T extends StatusState>
    extends StatusCubit<T>
    implements Refreshable {
  RefreshableStatusCubit(super.initialState) {
    _autoInit();
  }

  Future<void> _autoInit() async {
    try {
      await init();
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
  }
}
