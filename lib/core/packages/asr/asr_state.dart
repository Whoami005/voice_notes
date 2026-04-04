part of 'asr_cubit.dart';

class AsrState extends StatusState {
  /// Выбрана ли модель пользователем
  final bool hasModel;

  /// Название текущей модели (для отображения в UI)
  final String? modelName;

  const AsrState({
    super.status,
    super.failure,
    this.hasModel = false,
    this.modelName,
  });

  /// ASR готов к транскрибации
  bool get isReady => isSuccess && hasModel;

  @override
  AsrState copyWith({
    Status? status,
    AppFailure? failure,
    bool? hasModel,
    String? modelName,
  }) {
    return AsrState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      hasModel: hasModel ?? this.hasModel,
      modelName: modelName ?? this.modelName,
    );
  }

  @override
  List<Object?> get props => [...super.props, hasModel, modelName];
}
