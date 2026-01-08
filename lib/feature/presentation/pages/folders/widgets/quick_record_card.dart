import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';

/// Карточка быстрой записи с динамическими состояниями
///
/// Показывает разный UI в зависимости от состояния записи:
/// - Idle: карточка с приглашением к записи
/// - Recording: пульсирующий индикатор + таймер + кнопки
/// - Transcribing: индикатор загрузки
class QuickRecordCard extends StatelessWidget {
  const QuickRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return BlocBuilder<RecordingCubit, RecordingState>(
      builder: (context, state) {
        final cubit = context.read<RecordingCubit>();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: _getBackgroundColor(state, themeColors),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: _getBorderColor(state, themeColors)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (state) {
              RecordingIdleState() => _IdleContent(
                key: const ValueKey('idle'),
                onTap: cubit.startRecording,
              ),
              RecordingActiveState(:final duration) => _RecordingContent(
                key: const ValueKey('recording'),
                duration: duration,
                onStop: cubit.stopRecording,
                onCancel: cubit.cancelRecording,
              ),
              RecordingTranscribingState() => const _TranscribingContent(
                key: ValueKey('transcribing'),
              ),
              _ => _IdleContent(
                key: const ValueKey('idle'),
                onTap: cubit.startRecording,
              ),
            },
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(
    RecordingState state,
    AppColorsExtension themeColors,
  ) {
    return switch (state) {
      RecordingActiveState() => themeColors.recordingBg,
      _ => themeColors.bgSecondary,
    };
  }

  Color _getBorderColor(RecordingState state, AppColorsExtension themeColors) {
    return switch (state) {
      RecordingActiveState() => themeColors.recordingPulse.withValues(
        alpha: 0.3,
      ),
      _ => themeColors.borderPrimary,
    };
  }
}

// ==================== Idle State ====================

class _IdleContent extends StatelessWidget {
  final VoidCallback? onTap;

  const _IdleContent({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          _MicIcon(),
          AppSpacer.p14,
          Expanded(child: _IdleTextContent()),
          Icon(
            Icons.arrow_forward_ios,
            size: AppSizes.iconSmall,
            color: context.themeColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      width: AppSizes.avatarLarge,
      height: AppSizes.avatarLarge,
      decoration: BoxDecoration(
        color: themeColors.accentPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.mic,
        color: themeColors.accentPrimary,
        size: AppSizes.iconLarge,
      ),
    );
  }
}

class _IdleTextContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Голос → Текст', style: textTheme.titleMedium),
        AppSpacer.p2,
        Text(
          'Запишите речь и скопируйте в буфер',
          style: textTheme.labelMedium?.copyWith(
            color: themeColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ==================== Recording State ====================

class _RecordingContent extends StatelessWidget {
  final Duration duration;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;

  const _RecordingContent({
    required this.duration,
    super.key,
    this.onStop,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cancel button
        _CircleButton(
          icon: Icons.close,
          size: 44,
          backgroundColor: themeColors.bgTertiary,
          iconColor: themeColors.textSecondary,
          onTap: onCancel,
        ),
        AppSpacer.p12,
        // Recording indicator + timer
        Expanded(
          child: Row(
            children: [
              _PulsingIndicator(color: themeColors.recordingPulse),
              AppSpacer.p10,
              Text(
                _formatDuration(duration),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              AppSpacer.p12,
              Expanded(child: _WaveformBars(color: themeColors.recordingPulse)),
            ],
          ),
        ),
        AppSpacer.p12,
        // Stop button
        _CircleButton(
          icon: Icons.send,
          size: 48,
          backgroundColor: themeColors.accentPrimary,
          iconColor: themeColors.textInverse,
          onTap: onStop,
          hasShadow: true,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ==================== Transcribing State ====================

class _TranscribingContent extends StatelessWidget {
  const _TranscribingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: themeColors.accentPrimary,
          ),
        ),
        AppSpacer.p12,
        Text(
          'Распознаю речь...',
          style: textTheme.bodyMedium?.copyWith(
            color: themeColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ==================== Shared Components ====================

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool hasShadow;

  const _CircleButton({
    required this.icon,
    required this.size,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: themeColors.accentGlow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  final Color color;

  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveformBars extends StatefulWidget {
  final Color color;

  const _WaveformBars({required this.color});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 8;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(barCount, (index) {
            // Create wave effect with offset
            final offset = index / barCount;
            final animValue = (_controller.value + offset) % 1.0;
            final height = 4.0 + (10.0 * _waveFunction(animValue));

            return Container(
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  double _waveFunction(double t) {
    // Sine wave for smooth animation
    return (1 + (t * 2 * 3.14159).sin()) / 2;
  }
}

extension on double {
  double sin() => _sin(this);
}

double _sin(double x) {
  // Simple sin approximation using dart:math would be better,
  // but using Taylor series for independence:
  // sin(x) ≈ x - x³/6 + x⁵/120
  final x2 = x * x;
  return x * (1 - x2 / 6 * (1 - x2 / 20));
}
