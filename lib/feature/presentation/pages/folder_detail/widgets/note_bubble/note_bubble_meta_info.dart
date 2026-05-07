part of 'note_bubble.dart';

class _MetaInfo extends StatelessWidget {
  final NoteEntity note;

  const _MetaInfo({required this.note});

  @override
  Widget build(BuildContext context) {
    final metaStyle = context.textTheme.labelSmall;
    final sourceDuration = note.origin.sourceDuration;
    final detectedLanguageCode = note.origin.detectedLanguageCode?.trim() ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(DateTimeFormatter.time(note.createdAt), style: metaStyle),
        if (sourceDuration != null) ...[
          const _Dot(),
          Text(DurationFormatter.compact(sourceDuration), style: metaStyle),
        ],
        if (detectedLanguageCode.isNotEmpty) ...[
          const _Dot(),
          Text(detectedLanguageCode, style: metaStyle),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final color = context.themeColors.textTertiary;

    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
