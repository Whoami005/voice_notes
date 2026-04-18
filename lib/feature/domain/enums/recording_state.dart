/// Состояние UI компонента RecordingInput.
///
/// Значение `transcribing` исторически существовало для folder-режима, но
/// после переезда на очередь транскрибации прогресс заметки отображается
/// per-note в списке (`note_bubble`), а не в баре. Квик-рекорд использует
/// отдельный флаг `state.isTranscribing` через extension, UI-enum ему не
/// нужен. Так что сейчас бар-виджет знает только `idle` и `recording`.
enum RecordingInputState { idle, recording }

enum SearchFilter { all, text, tags, date }
