part of 'recording_input.dart';

class _RecordingState extends StatefulWidget {
  final Duration duration;
  final List<double> amplitudes;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;

  const _RecordingState({
    required this.duration,
    required this.amplitudes,
    this.onStopRecording,
    this.onCancelRecording,
  });

  @override
  State<_RecordingState> createState() => _RecordingStateState();
}

class _RecordingStateState extends State<_RecordingState>
    with SingleTickerProviderStateMixin {
  /// Доля ширины капсулы, после которой жест считается отменой.
  static const double _cancelThreshold = 0.4;

  /// Задержка перед появлением подсказки про свайп.
  static const Duration _hintDelay = Duration(seconds: 1);

  static const Duration _snapBackDuration = Duration(milliseconds: 240);

  /// Ширина «корзины», вылезающей справа при свайпе.
  static const double _trashRevealWidth = 70;

  /// Отступ подсказки вниз от нижнего края капсулы. Подсказка рендерится в
  /// `Stack(clipBehavior: Clip.none)` и не занимает места в layout — попадает
  /// в gap между баром и safe-area, не сдвигая ленту заметок наверху.
  static const double _hintOverhang = 22;

  static const double _hintIconSize = 14;

  static const double _capsuleShadowBlur = 20;
  static const double _capsuleShadowSpread = -2;

  double _dragOffset = 0;
  bool _hintVisible = false;
  double _snapFrom = 0;

  late final AnimationController _snapController;
  late final Animation<double> _snapAnimation;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapAnimation = CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    );
    _snapController.addListener(_onSnapTick);

    _hintTimer = Timer(_hintDelay, () {
      if (mounted) setState(() => _hintVisible = true);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _snapController
      ..removeListener(_onSnapTick)
      ..dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(() {
      _dragOffset = _snapFrom * (1.0 - _snapAnimation.value);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: AppSizes.recordingBarHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final capsuleWidth = constraints.maxWidth;
              final threshold = capsuleWidth * _cancelThreshold;
              final revealOpacity = threshold == 0
                  ? 0.0
                  : (_dragOffset.abs() / threshold).clamp(0.0, 1.0);
              final fadeOpacity = 1.0 - (revealOpacity * 0.55);

              return Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: _trashRevealWidth,
                    child: Opacity(
                      opacity: revealOpacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeColors.recordingPulse.withValues(
                            alpha: 0.18,
                          ),
                          border: Border.all(
                            color: themeColors.recordingPulse.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.recordingBarRadius,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.delete_outline,
                          size: AppSizes.iconMedium,
                          color: themeColors.recordingPulse,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_dragOffset, 0),
                    child: Opacity(
                      opacity: fadeOpacity,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragOffset = (_dragOffset + details.delta.dx)
                                .clamp(-capsuleWidth, 0.0);
                          });
                        },
                        onHorizontalDragEnd: (_) {
                          if (_dragOffset.abs() >= threshold) {
                            HapticFeedback.mediumImpact();
                            widget.onCancelRecording?.call();
                          } else {
                            _snapFrom = _dragOffset;
                            _snapController.forward(from: 0);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.recordingBarRadius,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: AppSizes.blurXL,
                              sigmaY: AppSizes.blurXL,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.p8,
                                AppSizes.p8,
                                AppSizes.p10,
                                AppSizes.p8,
                              ),
                              decoration: BoxDecoration(
                                color: themeColors.recordingBg.withValues(
                                  alpha: 0.85,
                                ),
                                border: Border.all(
                                  color: themeColors.recordingPulse.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.recordingBarRadius,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColors.recordingPulse
                                        .withValues(alpha: 0.15),
                                    blurRadius: _capsuleShadowBlur,
                                    spreadRadius: _capsuleShadowSpread,
                                  ),
                                ],
                              ),
                              child: Row(
                                spacing: AppSizes.p10,
                                children: [
                                  _CancelXButton(
                                    color: themeColors.textSecondary,
                                    onTap: widget.onCancelRecording,
                                  ),
                                  _PulseDot(color: themeColors.recordingPulse),
                                  Text(
                                    _formatDuration(widget.duration),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: themeColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _LiveWaveform(
                                      amplitudes: widget.amplitudes,
                                      color: themeColors.recordingPulse,
                                    ),
                                  ),
                                  _SendCircle(
                                    backgroundColor: themeColors.accentPrimary,
                                    iconColor: themeColors.textInverse,
                                    glowColor: themeColors.accentGlow,
                                    onTap: widget.onStopRecording,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -_hintOverhang,
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _hintVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSizes.p4,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      size: _hintIconSize,
                      color: themeColors.textTertiary,
                    ),
                    Text(
                      l10n.recordingSwipeToCancel,
                      style: textTheme.bodySmall?.copyWith(
                        color: themeColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
