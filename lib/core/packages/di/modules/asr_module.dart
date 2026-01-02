import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/asr/sherpa_asr_service.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';

@module
abstract class AsrModule {
  @singleton
  @preResolve
  Future<AsrService> asrService(ModelRepository modelRepo) async {
    final service = SherpaAsrService();

    final model = await modelRepo.getSelectedModel();
    if (model != null) {
      final path = await modelRepo.getModelPath(model.uuid);
      if (path != null) await service.initialize(model, path);
    }

    return service;
  }
}
