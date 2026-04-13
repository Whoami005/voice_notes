import 'package:flutter/material.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/storage_overview_stats.dart';

/// Header главного экрана хранилища: иконка, размер, счётчик, кнопка очистки.
class StorageOverviewHeader extends StatelessWidget {
  final StorageOverviewStats overview;
  final VoidCallback? onClearAll;

  const StorageOverviewHeader({
    required this.overview,
    this.onClearAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatarMedium,
                height: AppSizes.avatarMedium,
                decoration: BoxDecoration(
                  color: themeColors.accentMuted,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Icon(
                  Icons.audiotrack_rounded,
                  color: themeColors.accentPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storageTotalAudio,
                      style: textTheme.bodyMedium?.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                    AppSpacer.p4,
                    Text(
                      BytesFormatter.format(overview.totalBytes),
                      style: textTheme.titleLarge?.copyWith(
                        color: themeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacer.p2,
                    Text(
                      l10n.storageRecordingsCount(overview.totalCount),
                      style: textTheme.bodySmall?.copyWith(
                        color: themeColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!overview.isEmpty && onClearAll != null) ...[
            AppSpacer.p16,
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: themeColors.error,
                ),
                label: Text(
                  l10n.storageClearAllButton,
                  style: textTheme.labelLarge?.copyWith(
                    color: themeColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
