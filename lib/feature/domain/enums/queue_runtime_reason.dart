/// Runtime-статус дренажа очереди транскрибации. Ортогонален
/// `QueueBootstrapState` (который про lifecycle сервиса).
///
/// - [none] — очередь работает или простаивает без нотификации
/// - [awaitingModel] — bootstrap поднят, но ASR-модель не готова
///   (не выбрана / в процессе переключения)
/// - [interruptedPreviousRun] — предыдущая расшифровка оборвалась
///   до штатного завершения; нужен явный user resume
/// - [breakerTripped] — 3 подряд провала, circuit breaker на паузе
enum QueueRuntimeReason {
  none,
  awaitingModel,
  interruptedPreviousRun,
  breakerTripped,
}
