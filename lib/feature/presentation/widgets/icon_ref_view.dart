import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';

class IconRefView extends StatelessWidget {
  final IconRefEntity? icon;
  final Color? color;
  final double? size;
  final IconData fallbackIcon;
  final BorderRadius borderRadius;
  final BoxFit photoFit;

  const IconRefView({
    required this.icon,
    super.key,
    this.color,
    this.size,
    this.fallbackIcon = Icons.folder,
    this.borderRadius = BorderRadius.zero,
    this.photoFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return switch (icon) {
      MaterialIconRefEntity(:final key) => Icon(
        _mapMaterialIcon(key),
        color: color,
        size: size,
      ),
      SvgIconRefEntity(:final assetPath) => SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color!, BlendMode.srcIn),
        placeholderBuilder: (_) => _buildFallback(),
      ),
      PhotoIconRefEntity(:final filePath) => ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(filePath),
          width: size,
          height: size,
          fit: photoFit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      ),
      null => _buildFallback(),
    };
  }

  Widget _buildFallback() => Icon(fallbackIcon, color: color, size: size);

  IconData _mapMaterialIcon(MaterialIconKey key) => switch (key) {
    MaterialIconKey.folder => Icons.folder,
    MaterialIconKey.work => Icons.work,
    MaterialIconKey.book => Icons.book,
    MaterialIconKey.star => Icons.star,
    MaterialIconKey.favorite => Icons.favorite,
    MaterialIconKey.musicNote => Icons.music_note,
    MaterialIconKey.cameraAlt => Icons.camera_alt,
    MaterialIconKey.code => Icons.code,
  };
}
