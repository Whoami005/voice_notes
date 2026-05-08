import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_notes/core/packages/export/app_data_export_models.dart';
import 'package:voice_notes/feature/domain/enums/share_result_status_enum.dart';

abstract interface class AppDataShareService {
  Future<ShareResultStatusEnum> shareBackup({
    required BuildContext context,
    required ExportArtifact artifact,
  });
}

@Singleton(as: AppDataShareService)
class AppDataShareServiceImpl implements AppDataShareService {
  final SharePlus _sharePlus;

  AppDataShareServiceImpl() : _sharePlus = SharePlus.instance;

  @visibleForTesting
  AppDataShareServiceImpl.test({required SharePlus sharePlus})
    : _sharePlus = sharePlus;

  @override
  Future<ShareResultStatusEnum> shareBackup({
    required BuildContext context,
    required ExportArtifact artifact,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    final result = await _sharePlus.share(
      ShareParams(
        files: [XFile(artifact.file.path)],
        fileNameOverrides: [artifact.fileName],
        sharePositionOrigin: origin,
      ),
    );

    return switch (result.status) {
      ShareResultStatus.success => ShareResultStatusEnum.success,
      ShareResultStatus.dismissed => ShareResultStatusEnum.dismissed,
      ShareResultStatus.unavailable => ShareResultStatusEnum.unavailable,
    };
  }
}
