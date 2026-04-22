part of 'asr_cubit.dart';

class AsrState extends StatusState {
  /// Выбрана ли модель пользователем
  final bool hasModel;

  final AsrModelEntity? model;

  const AsrState({
    super.status,
    super.failure,
    this.hasModel = false,
    this.model,
  });

  /// ASR готов к транскрибации
  bool get isReady => isSuccess && hasModel;

  @override
  AsrState copyWith({
    Status? status,
    AppFailure? failure,
    bool? hasModel,
    AsrModelEntity? Function()? model,
    AsrModelIdEnum? modelId,
    AsrModelType? modelType,
  }) {
    return AsrState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      hasModel: hasModel ?? this.hasModel,
      model: model != null ? model() : this.model,
    );
  }

  @override
  List<Object?> get props => [...super.props, hasModel, model];
}
