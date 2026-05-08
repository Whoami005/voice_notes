import 'dart:io';

import 'package:equatable/equatable.dart';

class AppDataExportOptions extends Equatable {
  final bool includeAudio;

  const AppDataExportOptions({this.includeAudio = false});

  @override
  List<Object?> get props => [includeAudio];
}

class AppDataExportSummary extends Equatable {
  final int notesCount;
  final int audioCount;
  final int audioBytes;

  const AppDataExportSummary({
    required this.notesCount,
    required this.audioCount,
    required this.audioBytes,
  });

  @override
  List<Object?> get props => [notesCount, audioCount, audioBytes];
}

class ExportArtifact {
  final File file;
  final String fileName;
  final DateTime exportedAt;
  final bool includesAudio;

  const ExportArtifact({
    required this.file,
    required this.fileName,
    required this.exportedAt,
    required this.includesAudio,
  });
}
