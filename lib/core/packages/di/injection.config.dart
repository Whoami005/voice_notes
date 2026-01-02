// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../../feature/data/local/data_sources/folder_local_data_source.dart'
    as _i377;
import '../../../feature/data/local/data_sources/model_local_data_source.dart'
    as _i130;
import '../../../feature/data/local/data_sources/note_local_data_source.dart'
    as _i798;
import '../../../feature/data/local/data_sources/tag_local_data_source.dart'
    as _i952;
import '../../../feature/data/repositories/folder_repository_impl.dart'
    as _i749;
import '../../../feature/data/repositories/model_repository_impl.dart' as _i465;
import '../../../feature/data/repositories/note_repository_impl.dart' as _i910;
import '../../../feature/data/repositories/tag_repository_impl.dart' as _i775;
import '../../../feature/domain/repositories/folder_repository.dart' as _i500;
import '../../../feature/domain/repositories/model_repository.dart' as _i56;
import '../../../feature/domain/repositories/note_repository.dart' as _i1032;
import '../../../feature/domain/repositories/tag_repository.dart' as _i484;
import '../app_router/app_router.dart' as _i796;
import '../asr/asr_service.dart' as _i233;
import '../audio/audio_recording_service.dart' as _i571;
import '../db/object_box/objectbox_database.dart' as _i88;
import '../db/transaction_manager.dart' as _i138;
import '../downloader/download_manager.dart' as _i551;
import 'modules/asr_module.dart' as _i835;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final asrModule = _$AsrModule();
    gh.singleton<_i796.AppRouter>(() => _i796.AppRouter());
    gh.singleton<_i571.AudioRecordingService>(
      () => _i571.AudioRecordingService(),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i551.DownloadManager>(
      () {
        final i = _i551.DownloadManager();
        return i.init().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i88.DatabaseClient>(
      () => _i88.ObjectBoxDatabase.create(),
      preResolve: true,
      dispose: (i) => i.close(),
    );
    gh.singleton<_i952.TagLocalDataSource>(
      () => _i952.TagLocalDataSourceImpl(gh<_i88.DatabaseClient>()),
    );
    gh.singleton<_i377.FolderLocalDataSource>(
      () => _i377.FolderLocalDataSourceImpl(gh<_i88.DatabaseClient>()),
    );
    gh.singleton<_i798.NoteLocalDataSource>(
      () => _i798.NoteLocalDataSourceImpl(gh<_i88.DatabaseClient>()),
    );
    gh.singleton<_i130.ModelLocalDataSource>(
      () => _i130.ModelLocalDataSourceImpl(gh<_i88.DatabaseClient>()),
    );
    gh.singleton<_i56.ModelRepository>(
      () => _i465.ModelRepositoryImpl(
        gh<_i130.ModelLocalDataSource>(),
        gh<_i551.DownloadManager>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i500.FolderRepository>(
      () => _i749.FolderRepositoryImpl(gh<_i377.FolderLocalDataSource>()),
    );
    gh.singleton<_i484.TagRepository>(
      () => _i775.TagRepositoryImpl(gh<_i952.TagLocalDataSource>()),
    );
    gh.singleton<_i138.TransactionManager>(
      () => _i138.TransactionManager(gh<_i88.DatabaseClient>()),
    );
    await gh.singletonAsync<_i233.AsrService>(
      () => asrModule.asrService(gh<_i56.ModelRepository>()),
      preResolve: true,
    );
    gh.singleton<_i1032.NoteRepository>(
      () => _i910.NoteRepositoryImpl(
        gh<_i798.NoteLocalDataSource>(),
        gh<_i377.FolderLocalDataSource>(),
        gh<_i952.TagLocalDataSource>(),
        gh<_i138.TransactionManager>(),
      ),
    );
    return this;
  }
}

class _$AsrModule extends _i835.AsrModule {}
