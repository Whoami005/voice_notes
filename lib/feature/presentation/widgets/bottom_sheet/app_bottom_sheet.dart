import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onClose;

  const AppBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.onClose,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    VoidCallback? onClose,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      builder: (context) =>
          AppBottomSheet(title: title, onClose: onClose, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            left: AppSizes.screenPadding,
            right: AppSizes.screenPadding,
            bottom: context.bottomInset + AppSizes.screenPadding,
          ),
          sliver: SliverList.list(
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.p8),
                          child: Icon(
                            Icons.close,
                            size: AppSizes.iconLarge,
                            color: themeColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacer.p16,
              ],
              child,
            ],
          ),
        ),
      ],
    );
  }
}
