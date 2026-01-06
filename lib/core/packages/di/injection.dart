import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
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

    await getIt.init(environment: environment);
    return const AppInitializationSuccess();
  } catch (e, s) {
    print('configureDependencies: $e\n$s');

    await getIt.reset();
    return AppInitializationFailure(error: e, stackTrace: s);
  }
}
