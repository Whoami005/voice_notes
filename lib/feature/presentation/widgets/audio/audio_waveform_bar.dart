import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Полоска прогресса с поддержкой seek через drag.
///
/// Если [waveformData] предоставлен — рисует waveform через CustomPainter.
/// Иначе — fallback на Slider.
class AudioWaveformBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final List<double>? waveformData;

  const AudioWaveformBar({
    required this.position,
    required this.duration,
    required this.onSeek,
    this.waveformData,
    super.key,
  });

  @override
  State<AudioWaveformBar> createState() => _AudioWaveformBarState();
}

class _AudioWaveformBarState extends State<AudioWaveformBar> {
  bool _isDragging = false;
  double _dragValue = 0;

  double get _progress {
    if (widget.duration.inMilliseconds == 0) return 0;
    if (_isDragging) return _dragValue;
    return widget.position.inMilliseconds / widget.duration.inMilliseconds;
  }

  // ─────────────────────────────────────────────────────────────
  // Slider callbacks
  // ─────────────────────────────────────────────────────────────

  double _sliderDisplayValue(double streamValue) =>
      _isDragging ? _dragValue : streamValue;

  void _onSliderDragStart(double value) => setState(() {
    _isDragging = true;
    _dragValue = value;
  });

  void _onSliderDragUpdate(double value) => setState(() => _dragValue = value);

  void _onSliderDragEnd(double value) {
    widget.onSeek(Duration(milliseconds: value.round()));
    setState(() => _isDragging = false);
  }

  // ─────────────────────────────────────────────────────────────
  // Waveform gesture callbacks
  // ─────────────────────────────────────────────────────────────

  void _onWaveformSeek(double localX, double totalWidth) {
    if (totalWidth <= 0 || widget.duration.inMilliseconds == 0) return;
    final ratio = (localX / totalWidth).clamp(0.0, 1.0);
    final position = Duration(
      milliseconds: (ratio * widget.duration.inMilliseconds).round(),
    );
    widget.onSeek(position);
  }

  void _onWaveformDragStart(DragStartDetails details, double totalWidth) {
    final ratio = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() {
      _isDragging = true;
      _dragValue = ratio;
    });
  }

  void _onWaveformDragUpdate(DragUpdateDetails details, double totalWidth) {
    final ratio = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() => _dragValue = ratio);
  }

  void _onWaveformDragEnd(DragEndDetails details) {
    final position = Duration(
      milliseconds: (_dragValue * widget.duration.inMilliseconds).round(),
    );
    widget.onSeek(position);
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final waveformData = widget.waveformData ?? [];

    if (waveformData.isNotEmpty) {
      return SizedBox(
        height: AppSizes.p32,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;

            return GestureDetector(
              onTapDown: (details) =>
                  _onWaveformSeek(details.localPosition.dx, totalWidth),
              onHorizontalDragStart: (details) =>
                  _onWaveformDragStart(details, totalWidth),
              onHorizontalDragUpdate: (details) =>
                  _onWaveformDragUpdate(details, totalWidth),
              onHorizontalDragEnd: _onWaveformDragEnd,
              child: CustomPaint(
                size: Size(totalWidth, AppSizes.p32),
                painter: _WaveformPainter(
                  data: waveformData,
                  progress: _progress.clamp(0.0, 1.0),
                  activeColor: themeColors.accentPrimary,
                  inactiveColor: themeColors.borderSecondary,
                ),
              ),
            );
          },
        ),
      );
    }

    final sliderMax = widget.duration.inMilliseconds.toDouble();
    final sliderValue = widget.position.inMilliseconds
        .clamp(0, widget.duration.inMilliseconds)
        .toDouble();
    final isInteractive = sliderMax > 0;

    return SizedBox(
      height: AppSizes.p32,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: Slider(
          value: _sliderDisplayValue(sliderValue),
          max: isInteractive ? sliderMax : 1,
          onChangeStart: isInteractive ? _onSliderDragStart : null,
          onChanged: isInteractive ? _onSliderDragUpdate : null,
          onChangeEnd: isInteractive ? _onSliderDragEnd : null,
          activeColor: themeColors.accentPrimary,
          inactiveColor: themeColors.borderSecondary,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.data,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  static const double barWidth = 2;
  static const double barGap = 1.5;
  static const double minBarHeight = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const totalBarWidth = barWidth + barGap;
    final progressX = size.width * progress;

    for (var i = 0; i < data.length; i++) {
      final x = i * totalBarWidth;
      if (x > size.width) break;

      final barHeight = (data[i] * size.height).clamp(
        minBarHeight,
        size.height,
      );
      final y = (size.height - barHeight) / 2;

      final paint = Paint()
        ..color = x < progressX ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.data != data;
}
