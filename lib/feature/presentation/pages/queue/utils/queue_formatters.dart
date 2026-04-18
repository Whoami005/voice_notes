import 'package:intl/intl.dart';

String truncate(String text, int max) {
  final trimmed = text.trim();
  if (trimmed.length <= max) return trimmed;

  return '${trimmed.substring(0, max).trimRight()}…';
}

String formatShortTimestamp(DateTime ts) =>
    DateFormat('dd.MM HH:mm').format(ts);

String formatTimestamp(DateTime ts) =>
    DateFormat('dd.MM.yyyy HH:mm').format(ts);

String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (d.inHours >= 1) return '${d.inHours}:$minutes:$seconds';

  return '$minutes:$seconds';
}
