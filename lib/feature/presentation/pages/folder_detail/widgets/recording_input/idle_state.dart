part of 'recording_input.dart';

/// Доля высоты экрана, до которой может разрастись idle-капсула при
/// многострочном вводе. ~30% даёт ~10 строк на iPhone — достаточно для
/// длинной заметки, не закрывая большую часть экрана.
const double _idleMaxHeightFraction = 0.3;

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
    if (widget.textController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final screenHeight = context.screenSize.height;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSizes.recordingBarHeight,
        maxHeight: screenHeight * _idleMaxHeightFraction,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.recordingBarRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.blurXL,
            sigmaY: AppSizes.blurXL,
          ),
          child: Container(
            padding: const EdgeInsets.only(
              bottom: AppSizes.p6,
              left: AppSizes.p10,
              right: AppSizes.p10,
            ),
            decoration: BoxDecoration(
              color: themeColors.bgSecondary.withValues(alpha: 0.7),
              border: Border.all(color: themeColors.borderPrimary),
              borderRadius: BorderRadius.circular(AppSizes.recordingBarRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSizes.p8,
              children: [
                if (widget.onUploadFile != null)
                  _GhostIconButton(
                    icon: Icons.attach_file_rounded,
                    color: themeColors.textSecondary,
                    onTap: widget.onUploadFile,
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: textTheme.bodyMedium?.copyWith(
                      color: themeColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: context.l10n.recordingInputHint,
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: themeColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSizes.p6,
                      ),
                      fillColor: AppColors.transparent,
                    ),
                  ),
                ),
                _IdleActionCircle(
                  hasText: _hasText,
                  backgroundColor: themeColors.accentPrimary,
                  iconColor: themeColors.textInverse,
                  glowColor: themeColors.accentGlow,
                  onSend: _onSubmit,
                  onStartRecording: widget.onStartRecording,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
