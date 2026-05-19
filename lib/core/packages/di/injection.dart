import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/asr/asr_vad_asset_installer.dart';
import 'package:voice_notes/core/packages/di/app_initialization_result.dart';
import 'package:voice_notes/core/packages/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<AppInitializationResult> configureDependencies({
  String environment = 'prod',
  bool reset = false,
}) async {
  try {
    if (reset) await getIt.reset();

    await AsrVadAssetInstaller().ensureInstalled();
    await getIt.init(environment: environment);

    return const AppInitializationSuccess();
  } catch (e, s) {
    developer.log(
      'configureDependencies failed',
      name: 'configureDependencies',
      error: e,
      stackTrace: s,
    );

    await getIt.reset();
    return AppInitializationFailure(error: e, stackTrace: s);
  }
}
