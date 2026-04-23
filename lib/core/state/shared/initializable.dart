/// Интерфейс для кубитов с методом инициализации.
///
/// При реализации автоматически добавляет кнопку "Повторить" на экране ошибки.
abstract class Initializable {
  Future<void> init();

  Future<void> refresh();
}
