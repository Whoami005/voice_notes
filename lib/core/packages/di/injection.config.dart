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
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../../feature/data/local/data_sources/folder_local_data_source.dart'
    as _i377;
import '../../../feature/data/local/data_sources/model_local_data_source.dart'
    as _i130;
import '../../../feature/data/local/data_sources/note_audio_local_data_source.dart'
    as _i790;
import '../../../feature/data/local/data_sources/note_local_data_source.dart'
    as _i798;
import '../../../feature/data/local/data_sources/tag_local_data_source.dart'
    as _i952;
import '../../../feature/data/local/preferences/recording_preferences.dart'
    as _i403;
import '../../../feature/data/local/preferences/transcription_queue_preferences.dart'
    as _i849;
import '../../../feature/data/repositories/folder_repository_impl.dart'
    as _i749;
import '../../../feature/data/repositories/model_repository_impl.dart' as _i465;
import '../../../feature/data/repositories/note_repository_impl.dart' as _i910;
import '../../../feature/data/repositories/storage_stats_repository_impl.dart'
    as _i803;
import '../../../feature/data/repositories/tag_repository_impl.dart' as _i775;
import '../../../feature/domain/repositories/folder_repository.dart' as _i500;
import '../../../feature/domain/repositories/model_repository.dart' as _i56;
import '../../../feature/domain/repositories/note_repository.dart' as _i1032;
import '../../../feature/domain/repositories/storage_stats_repository.dart'
    as _i221;
import '../../../feature/domain/repositories/tag_repository.dart' as _i484;
import '../app_router/app_router.dart' as _i796;
import '../asr/asr_service.dart' as _i233;
import '../asr/sherpa_asr_service.dart' as _i699;
import '../audio/audio_recording_service.dart' as _i571;
import '../db/object_box/objectbox_database.dart' as _i88;
import '../db/transaction_manager.dart' as _i138;
import '../downloader/download_manager.dart' as _i551;
import '../note_ingestion/note_ingestion_service.dart' as _i165;
import '../player/audio_playback_controller.dart' as _i99;
import '../player/controller/just_audio_playback_controller.dart' as _i451;
import '../transcription/transcription_queue_controller.dart' as _i971;
import '../transcription/transcription_queue_service.dart' as _i909;
import 'modules/prefs_module.dart' as _i12;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final prefsModule = _$PrefsModule();
    gh.singleton<_i796.AppRouter>(() => _i796.AppRouter());
    gh.singleton<_i571.AudioRecordingService>(
      () => _i571.AudioRecordingService(),
      dispose: (i) => i.dispose(),
    );
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => prefsModule.prefs(),
      preResolve: true,
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
    gh.singleton<_i233.AsrService>(() => _i699.SherpaAsrService());
    gh.singleton<_i790.NoteAudioLocalDataSource>(
      () => _i790.NoteAudioLocalDataSourceImpl(gh<_i88.DatabaseClient>()),
    );
    gh.singleton<_i99.AudioPlaybackController>(
      () => _i451.JustAudioPlaybackController(),
      dispose: (i) => i.dispose(),
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
    gh.singleton<_i1032.NoteRepository>(
      () => _i910.NoteRepositoryImpl(gh<_i798.NoteLocalDataSource>()),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i403.RecordingPreferences>(
      () => _i403.RecordingPreferences(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i849.TranscriptionQueuePreferences>(
      () => _i849.TranscriptionQueuePreferences(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i221.StorageStatsRepository>(
      () => _i803.StorageStatsRepositoryImpl(
        gh<_i790.NoteAudioLocalDataSource>(),
        gh<_i377.FolderLocalDataSource>(),
      ),
    );
    gh.singleton<_i484.TagRepository>(
      () => _i775.TagRepositoryImpl(gh<_i952.TagLocalDataSource>()),
    );
    gh.singleton<_i138.TransactionManager>(
      () => _i138.TransactionManager(gh<_i88.DatabaseClient>()),
    );
    await gh.singletonAsync<_i971.TranscriptionQueueController>(
      () {
        final i = _i909.TranscriptionQueueService(
          noteRepository: gh<_i1032.NoteRepository>(),
          asrService: gh<_i233.AsrService>(),
          preferences: gh<_i403.RecordingPreferences>(),
          queuePreferences: gh<_i849.TranscriptionQueuePreferences>(),
        );
        return i.start().then((_) => i);
      },
      preResolve: true,
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i165.NoteIngestionService>(
      () => _i165.NoteIngestionService(
        noteRepository: gh<_i1032.NoteRepository>(),
      ),
    );
    return this;
  }
}

class _$PrefsModule extends _i12.PrefsModule {}
