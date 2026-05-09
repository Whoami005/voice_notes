import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/extensions/map_extension.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/enums/transcription_task_type.dart';

class AppDataBackupManifest extends Equatable {
  final int schemaVersion;
  final String app;
  final String exportedAt;
  final bool includesAudio;
  final AppDataBackupCounts counts;

  const AppDataBackupManifest({
    required this.schemaVersion,
    required this.app,
    required this.exportedAt,
    required this.includesAudio,
    required this.counts,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'app': app,
    'exportedAt': exportedAt,
    'includesAudio': includesAudio,
    'counts': counts.toJson(),
  };

  factory AppDataBackupManifest.fromJson(Map<String, dynamic> json) {
    return AppDataBackupManifest(
      schemaVersion: json.integer('schemaVersion'),
      app: json.string('app'),
      exportedAt: json.string('exportedAt'),
      includesAudio: json.boolean('includesAudio'),
      counts: json.object('counts', AppDataBackupCounts.fromJson),
    );
  }

  @override
  List<Object?> get props => [
    schemaVersion,
    app,
    exportedAt,
    includesAudio,
    counts,
  ];
}

class AppDataBackupCounts extends Equatable {
  final int folders;
  final int tags;
  final int notes;
  final int audioFiles;

  const AppDataBackupCounts({
    required this.folders,
    required this.tags,
    required this.notes,
    required this.audioFiles,
  });

  Map<String, Object?> toJson() => {
    'folders': folders,
    'tags': tags,
    'notes': notes,
    'audioFiles': audioFiles,
  };

  factory AppDataBackupCounts.fromJson(Map<String, dynamic> json) {
    return AppDataBackupCounts(
      folders: json.integer('folders'),
      tags: json.integer('tags'),
      notes: json.integer('notes'),
      audioFiles: json.integer('audioFiles'),
    );
  }

  @override
  List<Object?> get props => [folders, tags, notes, audioFiles];
}

class AppDataBackupPayload extends Equatable {
  final AppDataBackupSettings settings;
  final List<AppDataBackupFolder> folders;
  final List<AppDataBackupTag> tags;
  final List<AppDataBackupNote> notes;

  const AppDataBackupPayload({
    required this.settings,
    required this.folders,
    required this.tags,
    required this.notes,
  });

  Map<String, Object?> toJson() => {
    'settings': settings.toJson(),
    'folders': [for (final folder in folders) folder.toJson()],
    'tags': [for (final tag in tags) tag.toJson()],
    'notes': [for (final note in notes) note.toJson()],
  };

  factory AppDataBackupPayload.fromJson(Map<String, dynamic> json) {
    return AppDataBackupPayload(
      settings: json.object('settings', AppDataBackupSettings.fromJson),
      folders: json.objects('folders', AppDataBackupFolder.fromJson),
      tags: json.objects('tags', AppDataBackupTag.fromJson),
      notes: json.objects('notes', AppDataBackupNote.fromJson),
    );
  }

  @override
  List<Object?> get props => [settings, folders, tags, notes];
}

class AppDataBackupSettings extends Equatable {
  final String themeMode;
  final String localeCode;
  final AppDataBackupRecordingSettings recording;
  final String? selectedModelId;

  const AppDataBackupSettings({
    required this.themeMode,
    required this.localeCode,
    required this.recording,
    required this.selectedModelId,
  });

  Map<String, Object?> toJson() => {
    'themeMode': themeMode,
    'localeCode': localeCode,
    'recording': recording.toJson(),
    'selectedModelId': selectedModelId,
  };

  factory AppDataBackupSettings.fromJson(Map<String, dynamic> json) {
    return AppDataBackupSettings(
      themeMode: json.string('themeMode'),
      localeCode: json.string('localeCode'),
      recording: json.object(
        'recording',
        AppDataBackupRecordingSettings.fromJson,
      ),
      selectedModelId: json.stringOrNull('selectedModelId'),
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    recording,
    selectedModelId,
  ];
}

class AppDataBackupRecordingSettings extends Equatable {
  final bool keepOriginals;

  const AppDataBackupRecordingSettings({required this.keepOriginals});

  Map<String, Object?> toJson() => {'keepOriginals': keepOriginals};

  factory AppDataBackupRecordingSettings.fromJson(Map<String, dynamic> json) {
    return AppDataBackupRecordingSettings(
      keepOriginals: json.boolean('keepOriginals'),
    );
  }

  @override
  List<Object?> get props => [keepOriginals];
}

class AppDataBackupFolder extends Equatable {
  final String uid;
  final String name;
  final String? description;
  final int colorArgb;
  final String iconRef;
  final String createdAt;
  final String updatedAt;

  const AppDataBackupFolder({
    required this.uid,
    required this.name,
    required this.description,
    required this.colorArgb,
    required this.iconRef,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toJson() => {
    'uid': uid,
    'name': name,
    'description': description,
    'colorArgb': colorArgb,
    'iconRef': iconRef,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory AppDataBackupFolder.fromJson(Map<String, dynamic> json) {
    return AppDataBackupFolder(
      uid: json.string('uid'),
      name: json.string('name'),
      description: json.stringOrNull('description'),
      colorArgb: json.integer('colorArgb'),
      iconRef: json.string('iconRef'),
      createdAt: json.string('createdAt'),
      updatedAt: json.string('updatedAt'),
    );
  }

  FolderObject toObject() {
    return FolderObject(
      uid: uid,
      name: name,
      description: description,
      colorValue: colorArgb,
      iconRef: iconRef,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    description,
    colorArgb,
    iconRef,
    createdAt,
    updatedAt,
  ];
}

class AppDataBackupTag extends Equatable {
  final String name;
  final int? colorArgb;
  final String createdAt;

  const AppDataBackupTag({
    required this.name,
    required this.colorArgb,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'colorArgb': colorArgb,
    'createdAt': createdAt,
  };

  factory AppDataBackupTag.fromJson(Map<String, dynamic> json) {
    return AppDataBackupTag(
      name: json.string('name'),
      colorArgb: json.integerOrNull('colorArgb'),
      createdAt: json.string('createdAt'),
    );
  }

  TagObject toObject() {
    return TagObject(
      name: name.toLowerCase().trim(),
      colorValue: colorArgb,
      createdAt: DateTime.parse(createdAt).toLocal(),
    );
  }

  @override
  List<Object?> get props => [name, colorArgb, createdAt];
}

class AppDataBackupNote extends Equatable {
  final String uuid;
  final String? folderId;
  final String text;
  final List<String> tagNames;
  final String status;
  final String? failureReason;
  final String createdAt;
  final String updatedAt;
  final AppDataBackupNoteOrigin origin;

  const AppDataBackupNote({
    required this.uuid,
    required this.folderId,
    required this.text,
    required this.tagNames,
    required this.status,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    required this.origin,
  });

  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'folderId': folderId,
    'text': text,
    'tagNames': tagNames,
    'status': status,
    'failureReason': failureReason,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'origin': origin.toJson(),
  };

  factory AppDataBackupNote.fromJson(Map<String, dynamic> json) {
    return AppDataBackupNote(
      uuid: json.string('uuid'),
      folderId: json.stringOrNull('folderId'),
      text: json.string('text'),
      tagNames: json.strings('tagNames'),
      status: json.string('status'),
      failureReason: json.stringOrNull('failureReason'),
      createdAt: json.string('createdAt'),
      updatedAt: json.string('updatedAt'),
      origin: json.object('origin', AppDataBackupNoteOrigin.fromJson),
    );
  }

  NoteObject toObject({
    required FolderObject? folder,
    required List<TagObject> tags,
    required NoteAudioObject? audio,
  }) {
    final note = NoteObject(
      uid: uuid,
      text: text,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      originTypeValue: origin.type.value,
      statusValue: _parseStatusValue(status),
      sourceDurationMs: origin.sourceDurationMs,
      transcriptionModelId: origin.transcription?.modelId,
      transcriptionLanguageCode: origin.transcription?.languageCode,
      transcriptionTaskTypeValue: origin.transcription?.taskTypeValue,
      transcribedAt: origin.transcription?.transcribedAt == null
          ? null
          : DateTime.parse(origin.transcription!.transcribedAt).toLocal(),
      transcriptionProcessingTimeMs: origin.transcription?.processingTimeMs,
      transcriptionStrategyValue: origin.transcription?.strategyUsedValue,
      transcriptionUsedVad: origin.transcription?.usedVad,
      transcriptionFellBackFromVad: origin.transcription?.fellBackFromVad,
      transcriptionEmotionLabel: origin.transcription?.emotionLabel,
      transcriptionEventLabel: origin.transcription?.eventLabel,
      transcriptionUsedItn: origin.transcription?.usedItn,
      transcriptionUsedPunctuation: origin.transcription?.usedPunctuation,
      failureReasonValue: _parseFailureReason(failureReason),
    );

    note.folder.target = folder;
    note.tags.addAll(tags);
    note.audio.target = audio;

    return note;
  }

  @override
  List<Object?> get props => [
    uuid,
    folderId,
    text,
    tagNames,
    status,
    failureReason,
    createdAt,
    updatedAt,
    origin,
  ];

  static int? _parseFailureReason(String? value) {
    if (value == null) return null;

    for (final reason in TranscriptionFailureReason.values) {
      if (reason.name == value) return reason.value;
    }

    return null;
  }

  static int _parseStatusValue(String value) {
    final status = TranscriptionStatus.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => throw StateError('Unknown transcription status: $value'),
    );

    return status.isTranscribing
        ? TranscriptionStatus.queued.value
        : status.value;
  }
}

enum AppDataBackupNoteOriginType { manual, audio }

extension AppDataBackupNoteOriginTypeX on AppDataBackupNoteOriginType {
  int get value => switch (this) {
    AppDataBackupNoteOriginType.manual => 0,
    AppDataBackupNoteOriginType.audio => 1,
  };
}

sealed class AppDataBackupNoteOrigin extends Equatable {
  final AppDataBackupNoteOriginType type;
  final int? sourceDurationMs;

  const AppDataBackupNoteOrigin({
    required this.type,
    required this.sourceDurationMs,
  });

  Map<String, Object?> toJson();

  AppDataBackupAudioFile? get audio => null;

  AppDataBackupTranscription? get transcription => null;

  List<AppDataBackupTranscriptionSegment> get transcriptionSegments => const [];

  AppDataBackupAudioOrigin? get asAudio => this is AppDataBackupAudioOrigin
      ? this as AppDataBackupAudioOrigin
      : null;

  factory AppDataBackupNoteOrigin.fromJson(Map<String, dynamic> json) {
    final type = json.string('type');
    return switch (type) {
      'manual' => const AppDataBackupManualOrigin(),
      'audio' => AppDataBackupAudioOrigin.fromJson(json),
      _ => throw StateError('Unknown note origin type: $type'),
    };
  }
}

final class AppDataBackupManualOrigin extends AppDataBackupNoteOrigin {
  const AppDataBackupManualOrigin()
    : super(type: AppDataBackupNoteOriginType.manual, sourceDurationMs: null);

  @override
  Map<String, Object?> toJson() => {'type': 'manual'};

  @override
  List<Object?> get props => [type];
}

final class AppDataBackupAudioOrigin extends AppDataBackupNoteOrigin {
  @override
  final AppDataBackupAudioFile? audio;
  @override
  final AppDataBackupTranscription? transcription;
  @override
  final List<AppDataBackupTranscriptionSegment> transcriptionSegments;

  const AppDataBackupAudioOrigin({
    required int sourceDurationMs,
    required this.audio,
    required this.transcription,
    required this.transcriptionSegments,
  }) : super(
         type: AppDataBackupNoteOriginType.audio,
         sourceDurationMs: sourceDurationMs,
       );

  factory AppDataBackupAudioOrigin.fromJson(Map<String, dynamic> json) {
    return AppDataBackupAudioOrigin(
      sourceDurationMs: json.integer('sourceDurationMs'),
      audio: json.objectOrNull('audio', AppDataBackupAudioFile.fromJson),
      transcription: json.objectOrNull(
        'transcription',
        AppDataBackupTranscription.fromJson,
      ),
      transcriptionSegments: json.objects(
        'transcriptionSegments',
        AppDataBackupTranscriptionSegment.fromJson,
      ),
    );
  }

  @override
  Map<String, Object?> toJson() => {
    'type': 'audio',
    'sourceDurationMs': sourceDurationMs,
    'audio': audio?.toJson(),
    'transcription': transcription?.toJson(),
    'transcriptionSegments': [
      for (final segment in transcriptionSegments) segment.toJson(),
    ],
  };

  @override
  List<Object?> get props => [
    type,
    sourceDurationMs,
    audio,
    transcription,
    transcriptionSegments,
  ];
}

class AppDataBackupAudioFile extends Equatable {
  final String relativePath;
  final int sizeBytes;
  final int sampleRate;
  final int durationMs;
  final bool fileIncluded;

  const AppDataBackupAudioFile({
    required this.relativePath,
    required this.sizeBytes,
    required this.sampleRate,
    required this.durationMs,
    required this.fileIncluded,
  });

  Map<String, Object?> toJson() => {
    'relativePath': relativePath,
    'sizeBytes': sizeBytes,
    'sampleRate': sampleRate,
    'durationMs': durationMs,
    'fileIncluded': fileIncluded,
  };

  factory AppDataBackupAudioFile.fromJson(Map<String, dynamic> json) {
    return AppDataBackupAudioFile(
      relativePath: json.string('relativePath'),
      sizeBytes: json.integer('sizeBytes'),
      sampleRate: json.integer('sampleRate'),
      durationMs: json.integer('durationMs'),
      fileIncluded: json.boolean('fileIncluded'),
    );
  }

  NoteAudioObject? toObject({required String? folderUid}) {
    if (!fileIncluded) return null;

    return NoteAudioObject(
      relativePath: relativePath,
      sizeBytes: sizeBytes,
      sampleRate: sampleRate,
      durationMs: durationMs,
      folderUid: folderUid,
    );
  }

  NoteAudioEntity toDomain() {
    return NoteAudioEntity(
      relativePath: relativePath,
      sizeBytes: sizeBytes,
      sampleRate: sampleRate,
      duration: Duration(milliseconds: durationMs),
    );
  }

  @override
  List<Object?> get props => [
    relativePath,
    sizeBytes,
    sampleRate,
    durationMs,
    fileIncluded,
  ];
}

class AppDataBackupTranscription extends Equatable {
  final String modelId;
  final String? languageCode;
  final String taskType;
  final String transcribedAt;
  final int processingTimeMs;
  final String strategyUsed;
  final bool usedVad;
  final bool fellBackFromVad;
  final String? emotionLabel;
  final String? eventLabel;
  final bool? usedItn;
  final bool? usedPunctuation;

  const AppDataBackupTranscription({
    required this.modelId,
    required this.languageCode,
    required this.taskType,
    required this.transcribedAt,
    required this.processingTimeMs,
    required this.strategyUsed,
    required this.usedVad,
    required this.fellBackFromVad,
    required this.emotionLabel,
    required this.eventLabel,
    required this.usedItn,
    required this.usedPunctuation,
  });

  Map<String, Object?> toJson() => {
    'modelId': modelId,
    'languageCode': languageCode,
    'taskType': taskType,
    'transcribedAt': transcribedAt,
    'processingTimeMs': processingTimeMs,
    'strategyUsed': strategyUsed,
    'usedVad': usedVad,
    'fellBackFromVad': fellBackFromVad,
    'emotionLabel': emotionLabel,
    'eventLabel': eventLabel,
    'usedItn': usedItn,
    'usedPunctuation': usedPunctuation,
  };

  factory AppDataBackupTranscription.fromJson(Map<String, dynamic> json) {
    final modelId = json.string('modelId');
    if (AsrModelIdEnum.fromValue(modelId) == null) {
      throw StateError('Unknown ASR model id: $modelId');
    }

    final taskType = json.string('taskType');
    final strategyUsed = json.string('strategyUsed');

    if (!TranscriptionTaskType.values.any((type) => type.name == taskType)) {
      throw StateError('Unknown transcription task type: $taskType');
    }

    if (!AsrTranscriptionStrategy.values.any(
      (strategy) => strategy.name == strategyUsed,
    )) {
      throw StateError('Unknown transcription strategy: $strategyUsed');
    }

    return AppDataBackupTranscription(
      modelId: modelId,
      languageCode: json.stringOrNull('languageCode'),
      taskType: taskType,
      transcribedAt: json.string('transcribedAt'),
      processingTimeMs: json.integer('processingTimeMs'),
      strategyUsed: strategyUsed,
      usedVad: json.boolean('usedVad'),
      fellBackFromVad: json.boolean('fellBackFromVad'),
      emotionLabel: json.stringOrNull('emotionLabel'),
      eventLabel: json.stringOrNull('eventLabel'),
      usedItn: json.booleanOrNull('usedItn'),
      usedPunctuation: json.booleanOrNull('usedPunctuation'),
    );
  }

  int get taskTypeValue => TranscriptionTaskType.values
      .firstWhere((type) => type.name == taskType)
      .value;

  int get strategyUsedValue => AsrTranscriptionStrategy.values
      .firstWhere((strategy) => strategy.name == strategyUsed)
      .value;

  @override
  List<Object?> get props => [
    modelId,
    languageCode,
    taskType,
    transcribedAt,
    processingTimeMs,
    strategyUsed,
    usedVad,
    fellBackFromVad,
    emotionLabel,
    eventLabel,
    usedItn,
    usedPunctuation,
  ];
}

class AppDataBackupTranscriptionSegment extends Equatable {
  final int index;
  final String text;
  final int startMs;
  final int endMs;
  final String? languageCode;
  final List<String>? tokens;
  final List<int>? tokenTimestampsMs;

  const AppDataBackupTranscriptionSegment({
    required this.index,
    required this.text,
    required this.startMs,
    required this.endMs,
    required this.languageCode,
    required this.tokens,
    required this.tokenTimestampsMs,
  });

  Map<String, Object?> toJson() => {
    'index': index,
    'text': text,
    'startMs': startMs,
    'endMs': endMs,
    'languageCode': languageCode,
    'tokens': tokens,
    'tokenTimestampsMs': tokenTimestampsMs,
  };

  factory AppDataBackupTranscriptionSegment.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppDataBackupTranscriptionSegment(
      index: json.integer('index'),
      text: json.string('text'),
      startMs: json.integer('startMs'),
      endMs: json.integer('endMs'),
      languageCode: json.stringOrNull('languageCode'),
      tokens: json.stringsOrNull('tokens'),
      tokenTimestampsMs: json.integersOrNull('tokenTimestampsMs'),
    );
  }

  NoteTranscriptionSegmentObject toObject({required NoteObject note}) {
    return NoteTranscriptionSegmentObject(
      index: index,
      text: text,
      startMs: startMs,
      endMs: endMs,
      languageCode: languageCode,
      tokensJson: tokens == null ? null : jsonEncode(tokens),
      tokenTimestampsMsJson: tokenTimestampsMs == null
          ? null
          : jsonEncode(tokenTimestampsMs),
    )..note.target = note;
  }

  @override
  List<Object?> get props => [
    index,
    text,
    startMs,
    endMs,
    languageCode,
    tokens,
    tokenTimestampsMs,
  ];
}
