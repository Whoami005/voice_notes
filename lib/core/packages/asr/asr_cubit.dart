import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/extensions/future_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/state/status/initializable_status_cubits.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';

part 'asr_state.dart';

/// Глобальный cubit жизненного цикла ASR сервиса.
///
/// Коммуникация с ModelsCubit — только через БД:
/// `ModelsCubit.selectModel()` → repo → `watchSelectedModel()` →
/// `_onSelectedModelChanged()`. Прямой связи между кубитами нет.
class AsrCubit extends InitializableStatusCubit<AsrState> {
  final AsrService _asrService;
  final ModelRepository _modelRepository;

  StreamSubscription<AsrModelEntity?>? _modelSubscription;

  AsrCubit({
    required AsrService asrService,
    required ModelRepository modelRepository,
  }) : _asrService = asrService,
       _modelRepository = modelRepository,
       super(const AsrState());

  @override
  Future<void> init() async {
    final model = await _modelRepository.getSelectedModel();

    model == null
        ? emitSuccess(const AsrState())
        : await _initializeWithModel(model);

    _subscribeToModelChanges();
  }

  Future<void> retry() async {
    final model = await _modelRepository.getSelectedModel();
    if (model != null) await _initializeWithModel(model);
  }

  void _subscribeToModelChanges() {
    _modelSubscription?.cancel();
    _modelSubscription = _modelRepository.watchSelectedModel().listen(
      _onSelectedModelChanged,
      onError: addError,
    );
  }

  Future<void> _onSelectedModelChanged(AsrModelEntity? model) async {
    if (model == null) {
      try {
        await _asrService.unloadModel();
      } catch (e, s) {
        logError(e, s);
      }
      emitSuccess(const AsrState());
      return;
    }

    if (model.uuid != _asrService.currentModel?.uuid) {
      await _initializeWithModel(model);
    }
  }

  Future<void> _initializeWithModel(AsrModelEntity model) async {
    try {
      emit(
        AsrState(
          status: Status.loading,
          hasModel: true,
          modelName: model.name,
          modelType: model.modelType,
        ),
      );

      final path = await _modelRepository.getModelPath(model.uuid.value);
      if (path == null) {
        emitError(const CustomFailure('Model files not found'));
        return;
      }

      await _asrService.switchModel(model, path).atLeast();

      emitSuccess(
        AsrState(
          hasModel: true,
          modelName: model.name,
          modelType: model.modelType,
        ),
      );
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  @override
  Future<void> close() {
    _modelSubscription?.cancel();
    return super.close();
  }
}
