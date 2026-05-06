import 'package:flutter/material.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/icon_ref_view.dart';

class FolderIconBadge extends StatelessWidget {
  final IconRefEntity? icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final IconData fallbackIcon;

  const FolderIconBadge({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    super.key,
    this.backgroundColor,
    this.border,
    this.fallbackIcon = Icons.folder,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final badgeBackground = backgroundColor ?? color.withValues(alpha: 0.15);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: badgeBackground,
        borderRadius: radius,
        border: border,
      ),
      child: switch (icon) {
        PhotoIconRefEntity() => IconRefView(
          icon: icon,
          size: size,
          color: color,
          borderRadius: radius,
          fallbackIcon: fallbackIcon,
        ),
        _ => Center(
          child: IconRefView(
            icon: icon,
            size: iconSize,
            color: color,
            borderRadius: radius,
            fallbackIcon: fallbackIcon,
          ),
        ),
      },
    );
  }
}
