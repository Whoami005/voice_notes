import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension DownloadStatusL10n on DownloadStatus {
  String statusTitle(AppLocalizations l10n) => switch (this) {
    DownloadStatus.idle => '',
    DownloadStatus.preparing => l10n.modelStatusPreparing,
    DownloadStatus.queued => l10n.modelStatusQueued,
    DownloadStatus.downloading => l10n.modelStatusDownloading,
    DownloadStatus.extracting => l10n.modelStatusExtracting,
    DownloadStatus.completed => '',
    DownloadStatus.paused => l10n.modelStatusPaused,
    DownloadStatus.cancelled => l10n.modelStatusCancelled,
    DownloadStatus.failed => l10n.modelStatusError,
  };
}
