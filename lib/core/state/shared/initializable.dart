/// Интерфейс для кубитов с методом инициализации.
///
/// При реализации автоматически добавляет кнопку "Повторить" на экране ошибки.
abstract class Initializable {
  Future<void> init();
}

/// Расширяет Initializable методом refresh для обновления без loading.
abstract class Refreshable implements Initializable {
  Future<void> refresh();
}
