part of 'recording_input.dart';

/// Живой waveform во время записи. Рисует амплитуды через CustomPainter
/// в `RepaintBoundary` (изоляция перерисовок).
///
/// Новый сэмпл всегда у правого края, старые уходят влево — визуально запись
/// «течёт» направо налево.
class _LiveWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const _LiveWaveform({required this.amplitudes, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 28,
        child: CustomPaint(
          painter: _LiveWaveformPainter(amplitudes: amplitudes, color: color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _LiveWaveformPainter({required this.amplitudes, required this.color});

  static const double _barWidth = 2;
  static const double _barGap = 2;
  static const double _minBarHeight = 2;
  static const Radius _barRadius = Radius.circular(1);

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    const totalBarWidth = _barWidth + _barGap;

    for (var i = amplitudes.length - 1; i >= 0; i--) {
      final indexFromRight = amplitudes.length - 1 - i;
      final x = size.width - _barWidth - indexFromRight * totalBarWidth;
      if (x < 0) break;

      final h = (amplitudes[i] * size.height).clamp(_minBarHeight, size.height);
      final y = (size.height - h) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, _barWidth, h), _barRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LiveWaveformPainter old) =>
      old.amplitudes != amplitudes || old.color != color;
}
