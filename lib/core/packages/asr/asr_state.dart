part of 'asr_cubit.dart';

class AsrState extends StatusState {
  /// Выбрана ли модель пользователем
  final bool hasModel;

  //TODO: почему бы не хранить модель полностью ?
  /// Название текущей модели (для отображения в UI)
  final String? modelName;

  /// Тип выбранной модели (whisper / parakeet). Нужен подписчикам для
  /// оценок времени транскрибации (ETA) по RTF-таблице.
  final AsrModelType? modelType;

  const AsrState({
    super.status,
    super.failure,
    this.hasModel = false,
    this.modelName,
    this.modelType,
  });

  /// ASR готов к транскрибации
  bool get isReady => isSuccess && hasModel;

  @override
  AsrState copyWith({
    Status? status,
    AppFailure? failure,
    bool? hasModel,
    String? modelName,
    AsrModelType? modelType,
  }) {
    return AsrState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      hasModel: hasModel ?? this.hasModel,
      modelName: modelName ?? this.modelName,
      modelType: modelType ?? this.modelType,
    );
  }

  @override
  List<Object?> get props => [...super.props, hasModel, modelName, modelType];
}
