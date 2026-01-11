import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart';

class RecordingInput extends StatelessWidget {
  final RecordingInputState state;
  final Duration recordingDuration;
  final String? transcribingText;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onUploadFile;

  /// Controller for text input in idle state
  final TextEditingController? textController;

  /// Callback when user submits text note
  final ValueChanged<String>? onTextSubmit;

  const RecordingInput({
    required this.state,
    this.recordingDuration = Duration.zero,
    this.transcribingText,
    this.onStartRecording,
    this.onStopRecording,
    this.onCancelRecording,
    this.onUploadFile,
    this.textController,
    this.onTextSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RecordingInputState.idle => _IdleState(
        onStartRecording: onStartRecording,
        onUploadFile: onUploadFile,
        textController: textController,
        onTextSubmit: onTextSubmit,
      ),
      RecordingInputState.recording => _RecordingState(
        duration: recordingDuration,
        onStopRecording: onStopRecording,
        onCancelRecording: onCancelRecording,
      ),
      RecordingInputState.transcribing => _TranscribingState(
        text: transcribingText,
      ),
    };
  }
}

class _IdleState extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onUploadFile;
  final TextEditingController? textController;
  final ValueChanged<String>? onTextSubmit;

  const _IdleState({
    this.onStartRecording,
    this.onUploadFile,
    this.textController,
    this.onTextSubmit,
  });

  @override
  State<_IdleState> createState() => _IdleStateState();
}

class _IdleStateState extends State<_IdleState> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.textController ?? TextEditingController();
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onSubmit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    widget.onTextSubmit?.call(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // Dispose only if we created it
    if (widget.textController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Row(
      children: [
        _CircleButton(
          icon: Icons.upload_file_outlined,
          size: AppSizes.buttonSmallHeight,
          backgroundColor: themeColors.bgTertiary,
          iconColor: themeColors.textSecondary,
          onTap: widget.onUploadFile,
        ),
        AppSpacer.p12,
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            decoration: BoxDecoration(
              color: themeColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
            child: TextField(
              controller: _controller,
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Введите текст или запишите...',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: themeColors.textTertiary,
                ),
                border: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSizes.p14,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _onSubmit(),
            ),
          ),
        ),
        AppSpacer.p12,
        _ActionButton(
          hasText: _hasText,
          onSend: _onSubmit,
          onStartRecording: widget.onStartRecording,
        ),
      ],
    );
  }
}

class _RecordingState extends StatelessWidget {
  final Duration duration;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;

  const _RecordingState({
    required this.duration,
    this.onStopRecording,
    this.onCancelRecording,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Row(
      children: [
        _CircleButton(
          icon: Icons.close,
          size: AppSizes.micButtonSize,
          backgroundColor: themeColors.bgTertiary,
          iconColor: themeColors.textSecondary,
          onTap: onCancelRecording,
        ),
        AppSpacer.p12,
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: themeColors.recordingBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            ),
            child: Row(
              children: [
                _RecordingIndicator(color: themeColors.recordingPulse),
                AppSpacer.p12,
                Text(
                  _formatDuration(duration),
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacer.p12,
                Expanded(
                  child: _WaveformBars(color: themeColors.recordingPulse),
                ),
              ],
            ),
          ),
        ),
        AppSpacer.p12,
        _CircleButton(
          icon: Icons.send,
          size: AppSizes.micButtonSize,
          backgroundColor: themeColors.accentPrimary,
          iconColor: themeColors.textInverse,
          onTap: onStopRecording,
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

class _TranscribingState extends StatelessWidget {
  final String? text;

  const _TranscribingState({this.text});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.bubbleRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: themeColors.accentPrimary,
            ),
          ),
          AppSpacer.p12,
          Expanded(
            child: Text(
              text ?? 'Транскрибирование...',
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated action button that switches between mic and send icons
class _ActionButton extends StatelessWidget {
  final bool hasText;
  final VoidCallback? onSend;
  final VoidCallback? onStartRecording;

  const _ActionButton({
    required this.hasText,
    this.onSend,
    this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: hasText ? onSend : onStartRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: AppSizes.micButtonSize,
        height: AppSizes.micButtonSize,
        decoration: BoxDecoration(
          color: themeColors.accentPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: themeColors.accentGlow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            hasText ? Icons.send : Icons.mic,
            key: ValueKey(hasText),
            color: themeColors.textInverse,
            size: AppSizes.iconLarge,
          ),
        ),
      ),
    );
  }
}

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
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: AppSizes.iconLarge),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final Color color;

  const _RecordingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final Color color;

  const _WaveformBars({required this.color});

  @override
  Widget build(BuildContext context) {
    // Static bars for basic structure (animations can be added later)
    final heights = [
      8.0,
      16.0,
      12.0,
      20.0,
      8.0,
      24.0,
      16.0,
      12.0,
      20.0,
      8.0,
      16.0,
      12.0,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(heights.length, (index) {
        final height = heights[index];

        return Container(
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
