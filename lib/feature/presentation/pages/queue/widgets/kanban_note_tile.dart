import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/queue/utils/queue_formatters.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/status_dot.dart';

class KanbanNoteTile extends StatelessWidget {
  final NoteEntity note;
  final Color statusColor;
  final bool pulse;
  final String footerHint;
  final Color footerHintColor;
  final IconData? footerHintIcon;
  final List<Widget> actions;

  const KanbanNoteTile({
    required this.note,
    required this.statusColor,
    required this.footerHint,
    required this.footerHintColor,
    this.actions = const [],
    this.pulse = false,
    this.footerHintIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final title = note.text.trim().isEmpty
        ? l10n.queueItemDefaultTitle(note.displayId)
        : truncate(note.text, 60);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p10,
          AppSizes.p8,
          AppSizes.p8,
          AppSizes.p6,
        ),
        decoration: BoxDecoration(
          color: themeColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppSizes.p10),
          border: Border.all(
            color: themeColors.bgTertiary.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatShortTimestamp(note.createdAt),
                style: AppTypography.caption.copyWith(
                  color: themeColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
            AppSpacer.p4,
            Row(
              spacing: AppSizes.p8,
              children: [
                StatusDot(color: statusColor, pulse: pulse),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacer.p6,
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: themeColors.bgTertiary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              padding: const EdgeInsets.only(top: AppSizes.p6),
              child: Row(
                children: [
                  if (footerHintIcon != null) ...[
                    Icon(footerHintIcon, size: 12, color: footerHintColor),
                    AppSpacer.p4,
                  ],
                  Expanded(
                    child: Text(
                      footerHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: footerHintColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TileAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const TileAction({
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return IconButton(
      icon: Icon(icon, size: AppSizes.iconSmall, color: color),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: themeColors.bgSecondary,
        disabledBackgroundColor: themeColors.bgSecondary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(AppSizes.p4),
        minimumSize: const Size(AppSizes.p32, AppSizes.p32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.p6),
        ),
      ),
    );
  }
}
