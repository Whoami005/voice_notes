part of 'note_bubble.dart';

class _MetaInfo extends StatelessWidget {
  final NoteEntity note;

  const _MetaInfo({required this.note});

  @override
  Widget build(BuildContext context) {
    final metaStyle = context.textTheme.labelSmall;
    final sourceDuration = note.origin.sourceDuration;
    final detectedLanguageCode = note.origin.detectedLanguageCode?.trim() ?? '';
    final inlineChildren = <InlineSpan>[
      TextSpan(text: DateTimeFormatter.time(note.createdAt)),
    ];

    if (sourceDuration != null) {
      inlineChildren.addAll([
        const WidgetSpan(alignment: PlaceholderAlignment.middle, child: _Dot()),
        TextSpan(text: DurationFormatter.compact(sourceDuration)),
      ]);
    }

    if (detectedLanguageCode.isNotEmpty) {
      inlineChildren.addAll([
        const WidgetSpan(alignment: PlaceholderAlignment.middle, child: _Dot()),
        TextSpan(text: detectedLanguageCode),
      ]);
    }

    return Text.rich(
      TextSpan(style: metaStyle, children: inlineChildren),
      softWrap: true,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final color = context.themeColors.textTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
