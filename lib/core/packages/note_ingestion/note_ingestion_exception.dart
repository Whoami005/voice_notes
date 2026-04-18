import 'package:voice_notes/core/error/app_failure.dart';

/// Единственный публичный failure-класс `NoteIngestionService`.
///
/// [AppFailure] упакован внутри — вызывающий cubit сразу берёт его для UI
/// без перепроверки типа/пересборки сообщения.
final class NoteIngestionFailed implements Exception {
  final AppFailure failure;

  const NoteIngestionFailed(this.failure);

  @override
  String toString() => 'NoteIngestionFailed(${failure.message})';
}
