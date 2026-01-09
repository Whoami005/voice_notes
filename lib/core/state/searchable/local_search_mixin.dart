import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Миксин для добавления поиска с debounce к любому Cubit/Bloc.
///
/// Предоставляет поиск с дебаунсом для клиентской фильтрации.
/// Таймер управляется внутренне.
///
/// Пример:
/// ```dart
/// class FoldersCubit extends RefreshableAsyncCubit<FoldersState>
///     with LocalSearchMixin<FoldersState> {
///
///   @override
///   void onSearch(String query) {
///     whenData((data) => emitSuccess(data.copyWith(query: query)));
///   }
/// }
/// ```
mixin LocalSearchMixin<S> on BlocBase<S> {
  Timer? _debounceTimer;

  /// Debounce duration for search. Override to customize.
  Duration get searchDebounce => const Duration(milliseconds: 500);

  /// Вызывается после debounce. Реализуйте логику фильтрации.
  void onSearch(String query);

  /// Запустить поиск с debounce.
  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(searchDebounce, () => onSearch(query));
  }

  /// Запустить поиск немедленно (без debounce).
  void searchImmediate(String query) {
    _debounceTimer?.cancel();
    onSearch(query);
  }

  /// Очистить поиск.
  void clearSearch() {
    _debounceTimer?.cancel();
    onSearch('');
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
