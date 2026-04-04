import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/success_dialog.dart';

abstract final class _Styles {
  static const buttonSize = 60.0;
  static const maxRipples = 4;
  static const pulseDuration = Duration(milliseconds: 1500);
  static const gradientDuration = Duration(milliseconds: 2000);
  static const rippleSpawnInterval = Duration(milliseconds: 600);
  static const rippleDuration = Duration(milliseconds: 1800);

  // Dark theme
  static const darkIdleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A3A3C), Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
  );

  static const darkRecordingGradientColors = [
    Color(0xFF5A5A5C),
    Color(0xFF4A4A4C),
    Color(0xFF3A3A3C),
    Color(0xFF5A5A5C),
  ];

  // Light theme
  static const lightIdleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const lightRecordingGradientColors = [
    Color(0xFFFBBF24),
    Color(0xFFF59E0B),
    Color(0xFFD97706),
    Color(0xFFFBBF24),
  ];
}

class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isAsrReady = context.select((AsrCubit c) => c.state.isReady);

    if (!isAsrReady) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => RecordingCubit(
        recordingService: getIt<AudioRecordingService>(),
        asrService: getIt<AsrService>(),
        noteRepository: getIt<NoteRepository>(),
      ),
      child: BlocListener<RecordingCubit, RecordingState>(
        listener: _handleStateChange,
        child: const _VoiceRecordButtonContent(),
      ),
    );
  }

  void _handleStateChange(BuildContext context, RecordingState state) {
    switch (state) {
      case RecordingSuccessState(:final text):
        SuccessDialog.showClipboardSuccess(context, text: text);
      case RecordingErrorState(:final failure):
        ErrorDialog.showFromFailure(context, failure);
      default:
        break;
    }
  }
}

class _VoiceRecordButtonContent extends StatefulWidget {
  const _VoiceRecordButtonContent();

  @override
  State<_VoiceRecordButtonContent> createState() =>
      _VoiceRecordButtonContentState();
}

class _VoiceRecordButtonContentState extends State<_VoiceRecordButtonContent>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _gradientController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _gradientAnimation;

  Timer? _rippleSpawnTimer;
  final List<_RippleData> _ripples = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: _Styles.pulseDuration,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _gradientController = AnimationController(
      duration: _Styles.gradientDuration,
      vsync: this,
    );
    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gradientController.dispose();
    _rippleSpawnTimer?.cancel();
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _gradientController.repeat();
    _startRipples();
  }

  void _stopAnimations() {
    _pulseController
      ..stop()
      ..reset();
    _gradientController
      ..stop()
      ..reset();
    _stopRipples();
  }

  void _startRipples() {
    _rippleSpawnTimer = Timer.periodic(
      _Styles.rippleSpawnInterval,
      (_) => _spawnRipple(),
    );
  }

  void _stopRipples() {
    _rippleSpawnTimer?.cancel();
    _rippleSpawnTimer = null;
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _ripples.clear();
  }

  void _spawnRipple() {
    if (_ripples.length >= _Styles.maxRipples) return;

    final controller = AnimationController(
      duration: _Styles.rippleDuration,
      vsync: this,
    );

    final ripple = _RippleData(controller: controller);
    _ripples.add(ripple);

    controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _ripples.remove(ripple));
          controller.dispose();
        }
      })
      ..forward();

    setState(() {});
  }

  void _onTap() {
    final cubit = context.read<RecordingCubit>();
    final state = cubit.state;

    if (state is RecordingActiveState) {
      cubit.stopRecording();
      _stopAnimations();
    } else if (state is RecordingIdleState) {
      cubit.startRecording();
      _startAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingCubit, RecordingState>(
      builder: (context, state) {
        final isRecording = state.isRecording;
        final isTranscribing = state.isTranscribing;
        final duration = state is RecordingActiveState
            ? state.duration
            : Duration.zero;

        return SizedBox(
          width: _Styles.buttonSize,
          height: _Styles.buttonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isRecording)
                for (final ripple in _ripples)
                  Positioned.fill(
                    child: Center(
                      child: _RippleWidget(animation: ripple.controller),
                    ),
                  ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isRecording ? _pulseAnimation.value : 1,
                    child: child,
                  );
                },
                child: _AnimatedButton(
                  isRecording: isRecording,
                  isTranscribing: isTranscribing,
                  gradientAnimation: _gradientAnimation,
                  onTap: isTranscribing ? null : _onTap,
                ),
              ),
              if (isRecording)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _Styles.buttonSize + 10,
                  child: Center(child: _TimerBadge(duration: duration)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedButton extends StatelessWidget {
  final bool isRecording;
  final bool isTranscribing;
  final Animation<double> gradientAnimation;
  final VoidCallback? onTap;

  const _AnimatedButton({
    required this.isRecording,
    required this.isTranscribing,
    required this.gradientAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: gradientAnimation,
        builder: (context, child) {
          return Container(
            width: _Styles.buttonSize,
            height: _Styles.buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _buildGradient(isDarkMode),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: isRecording ? 0.3 : 0.15)
                    : const Color(
                        0xFFD97706,
                      ).withValues(alpha: isRecording ? 0.4 : 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                if (isRecording)
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
              ],
            ),
            child: Center(
              child: isTranscribing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : AnimatedScale(
                      scale: isRecording ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: AppSizes.iconMedium,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildGradient(bool isDarkMode) {
    if (!isRecording) {
      return isDarkMode ? _Styles.darkIdleGradient : _Styles.lightIdleGradient;
    }

    final shift = gradientAnimation.value;
    final colors = isDarkMode
        ? _Styles.darkRecordingGradientColors
        : _Styles.lightRecordingGradientColors;

    return LinearGradient(
      begin: Alignment(-1.0 + shift, -1.0 + shift),
      end: Alignment(1.0 + shift, 1.0 + shift),
      colors: colors,
      stops: const [0.0, 0.33, 0.66, 1.0],
    );
  }
}

class _RippleData {
  final AnimationController controller;

  _RippleData({required this.controller});
}

class _RippleWidget extends StatelessWidget {
  final Animation<double> animation;

  const _RippleWidget({required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final size = _Styles.buttonSize + (80 * animation.value);

        return Opacity(
          opacity: 1.0 - animation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final Duration duration;

  const _TimerBadge({required this.duration});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDuration(duration),
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF44403C),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}
