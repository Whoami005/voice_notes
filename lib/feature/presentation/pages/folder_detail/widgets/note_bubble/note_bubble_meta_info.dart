part of 'note_bubble.dart';

class _MetaInfo extends StatelessWidget {
  final NoteEntity note;

  const _MetaInfo({required this.note});

  @override
  Widget build(BuildContext context) {
    final metaStyle = context.textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatTime(note.createdAt), style: metaStyle),
        const _Dot(),
        Text(_formatDuration(note.duration), style: metaStyle),
        if (note.language.isNotEmpty) ...[
          const _Dot(),
          Text(note.language, style: metaStyle),
        ],
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
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
