part of 'voice_record_button.dart';

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

  final List<_RippleData> _ripples = [];
  Timer? _rippleSpawnTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: _VoiceRecordButtonStyles.pulseDuration,
      vsync: this,
    );
    _pulseAnimation =
        Tween<double>(
          begin: 1,
          end: _VoiceRecordButtonStyles.pulseScale,
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    _gradientController = AnimationController(
      duration: _VoiceRecordButtonStyles.gradientDuration,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingCubit, RecordingState>(
      builder: (context, state) {
        final colors = _getColors(context);
        final isDarkMode = context.isDarkMode;
        final isRecording = state.isRecording;
        final isTranscribing = state.isTranscribing;
        final isWaitingTranscriptionSlot = state.isWaitingTranscriptionSlot;
        final duration = state is RecordingActiveState
            ? state.duration
            : Duration.zero;

        return SizedBox(
          width: _VoiceRecordButtonStyles.buttonSize,
          height: _VoiceRecordButtonStyles.buttonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isRecording)
                for (final ripple in _ripples)
                  Positioned.fill(
                    child: Center(
                      child: _RippleWidget(
                        animation: ripple.controller,
                        colors: colors,
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
                child: _AnimatedVoiceButton(
                  colors: colors,
                  isDarkMode: isDarkMode,
                  isRecording: isRecording,
                  isTranscribing: isTranscribing,
                  gradientAnimation: _gradientAnimation,
                  onTap: isTranscribing ? null : _handleTap,
                ),
              ),
              if (isRecording)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      _VoiceRecordButtonStyles.buttonSize +
                      _VoiceRecordButtonStyles.timerBadgeOffset,
                  child: Center(
                    child: _TimerBadge(duration: duration, colors: colors),
                  ),
                ),
              if (isWaitingTranscriptionSlot)
                Positioned(
                  right: 0,
                  bottom:
                      _VoiceRecordButtonStyles.buttonSize +
                      _VoiceRecordButtonStyles.timerBadgeOffset,
                  child: _WaitingBadge(
                    label: context.l10n.quickRecordWaitingCurrentTranscription,
                    colors: colors,
                    maxWidth: _getWaitingBadgeMaxWidth(context),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  VoiceButtonColors _getColors(BuildContext context) => context.isDarkMode
      ? AppColors.dark.voiceButton
      : AppColors.light.voiceButton;

  double _getWaitingBadgeMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safePadding = MediaQuery.paddingOf(context);
    final availableWidth =
        screenWidth -
        safePadding.left -
        safePadding.right -
        (_VoiceRecordButtonStyles.waitingBadgeScreenPadding * 2);

    return availableWidth
        .clamp(0, _VoiceRecordButtonStyles.waitingBadgeMaxWidth)
        .toDouble();
  }

  void _handleTap() {
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
      _VoiceRecordButtonStyles.rippleSpawnInterval,
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
    if (_ripples.length >= _VoiceRecordButtonStyles.maxRipples) return;

    final controller = AnimationController(
      duration: _VoiceRecordButtonStyles.rippleDuration,
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
}
