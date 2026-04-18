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
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/transcription/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/success_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/toasts/app_toast.dart';

abstract final class _Styles {
  static const double buttonSize = 60;
  static const int maxRipples = 4;
  static const Duration pulseDuration = Duration(milliseconds: 1500);
  static const Duration gradientDuration = Duration(milliseconds: 2000);
  static const Duration rippleSpawnInterval = Duration(milliseconds: 600);
  static const Duration rippleDuration = Duration(milliseconds: 1800);
  static const double darkShadowBlur = AppSizes.blurXXL;
  static const double lightShadowBlur = AppSizes.blurLarge;
  static const double glowBlurRadius = AppSizes.blurXL;
  static const Offset shadowOffset = Offset(0, 8);
  static const double timerBadgeOffset = 10;
  static const double rippleExpansion = 80;
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
        playbackController: getIt<AudioPlaybackController>(),
        ingestionService: getIt<NoteIngestionService>(),
      ),
      child: BlocListener<RecordingCubit, RecordingState>(
        listener: _handleStateChange,
        child: const _VoiceRecordButtonContent(),
      ),
    );
  }

  void _handleStateChange(BuildContext context, RecordingState state) {
    switch (state) {
      ///TODO: для быстрой транскрибации давать приоритет и класть в начало очереди.
      case RecordingTranscribingState():
        // Quick Record синхронен и идёт через ту же FIFO-очередь команд
        // изолята, что и заметки пользователя в других папках. Если там
        // что-то есть — сообщим, что ждать придётся дольше.
        final queueTotal = context
            .read<TranscriptionQueueCubit>()
            .state
            .snapshot
            .total;
        if (queueTotal > 0) {
          AppToast.info(
            context,
            message: context.l10n.quickRecordWaitingQueue(queueTotal),
          );
        }
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
          if (mounted) {
            setState(() => _ripples.remove(ripple));
          } else {
            _ripples.remove(ripple);
          }
          controller.dispose();
        }
      })
      ..forward();

    if (mounted) setState(() {});
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
                      child: _RippleWidget(
                        animation: ripple.controller,
                        colors: _vbColors(context),
                      ),
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
                  bottom: _Styles.buttonSize + _Styles.timerBadgeOffset,
                  child: Center(
                    child: _TimerBadge(
                      duration: duration,
                      colors: _vbColors(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  VoiceButtonColors _vbColors(BuildContext context) => context.isDarkMode
      ? AppColors.dark.voiceButton
      : AppColors.light.voiceButton;
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
    final vb = isDarkMode
        ? AppColors.dark.voiceButton
        : AppColors.light.voiceButton;

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
              gradient: _buildGradient(vb),
              border: Border.all(
                color: isRecording ? vb.borderActive : vb.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: vb.shadow,
                  blurRadius: isDarkMode
                      ? _Styles.darkShadowBlur
                      : _Styles.lightShadowBlur,
                  offset: _Styles.shadowOffset,
                ),
                if (isRecording)
                  BoxShadow(color: vb.glow, blurRadius: _Styles.glowBlurRadius),
              ],
            ),
            child: Center(
              child: isTranscribing
                  ? SizedBox(
                      width: AppSizes.iconLarge,
                      height: AppSizes.iconLarge,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.strokeMedium,
                        color: vb.icon,
                      ),
                    )
                  : AnimatedScale(
                      scale: isRecording ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.mic,
                        color: vb.icon,
                        size: AppSizes.iconMedium,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildGradient(VoiceButtonColors vb) {
    if (!isRecording) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: vb.idleGradient,
      );
    }

    final shift = gradientAnimation.value;
    return LinearGradient(
      begin: Alignment(-1.0 + shift, -1.0 + shift),
      end: Alignment(1.0 + shift, 1.0 + shift),
      colors: vb.activeGradient,
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
  final VoiceButtonColors colors;

  const _RippleWidget({required this.animation, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final size =
            _Styles.buttonSize + (_Styles.rippleExpansion * animation.value);

        return Opacity(
          opacity: 1.0 - animation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colors.ripple, AppColors.transparent],
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
  final VoiceButtonColors colors;

  const _TimerBadge({required this.duration, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurModerate,
          sigmaY: AppSizes.blurModerate,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p6,
          ),
          decoration: BoxDecoration(
            color: colors.timerBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: Text(
            _formatDuration(duration),
            style: AppTypography.caption.copyWith(
              color: colors.timerText,
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
