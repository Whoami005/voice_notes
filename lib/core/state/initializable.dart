/// Интерфейс для блоков/кубитов с методом инициализации
///
/// Реализуйте этот интерфейс в своём блоке/кубите, чтобы автоматически
/// добавить кнопку "Повторить" на экране ошибки.
///
/// Пример использования:
/// ```dart
/// class UsersCubit extends Cubit<UsersState> implements Initializable {
///   final UserRepository _repository;
///
///   UsersCubit(this._repository) : super(UsersState.initial());
///
///   @override
///   Future<void> init() async {
///     emit(state.copyWith(status: LogicStateStatus.loading));
///     try {
///       final users = await _repository.getUsers();
///       emit(state.copyWith(
///         status: LogicStateStatus.success,
///         users: users,
///       ));
///     } catch (e, s) {
///       final failure = AppFailure.handler(e, s);
///       emit(state.copyWith(
///         status: LogicStateStatus.error,
///         failure: failure,
///       ));
///     }
///   }
/// }
/// ```
abstract class Initializable {
  /// Метод инициализации данных
  ///
  /// Обычно вызывается при первой загрузке экрана или при повторной попытке
  /// после ошибки. Должен включать:
  /// - Установку статуса loading
  /// - Загрузку данных
  /// - Обработку ошибок
  Future<void> init();
}

/// Интерфейс для блоков/кубитов с методом обновления данных
///
/// Расширяет [Initializable], добавляя метод [refresh] для обновления данных
/// без полной переинициализации (например, без смены статуса на loading).
///
/// Используйте этот интерфейс, когда нужен pull-to-refresh или
/// фоновое обновление данных.
///
/// Пример использования:
/// ```dart
/// class ChatsCubit extends Cubit<ChatsState> implements Refreshable {
///   final ChatRepository _repository;
///
///   ChatsCubit(this._repository) : super(ChatsState.initial());
///
///   @override
///   Future<void> init() async {
///     emit(state.copyWith(status: LogicStateStatus.loading));
///     try {
///       final chats = await _repository.getChats();
///       emit(state.copyWith(
///         status: LogicStateStatus.success,
///         chats: chats,
///       ));
///     } catch (e, s) {
///       final failure = AppFailure.handler(e, s);
///       emit(state.copyWith(
///         status: LogicStateStatus.error,
///         failure: failure,
///       ));
///     }
///   }
///
///   @override
///   Future<void> refresh() async {
///     // Обновление без смены статуса на loading
///     try {
///       final chats = await _repository.getChats();
///       emit(state.copyWith(chats: chats));
///     } catch (e, s) {
///       final failure = AppFailure.handler(e, s);
///       ToastDialogs.showError(message: failure.message);
///     }
///   }
/// }
/// ```
abstract class Refreshable implements Initializable {
  /// Метод обновления данных
  ///
  /// Обычно вызывается при pull-to-refresh или фоновом обновлении.
  /// В отличие от [init], может не устанавливать статус loading,
  /// обновляя данные "тихо" в фоне.
  Future<void> refresh();
}
