import 'package:flutter/material.dart';

/// Вычисляет размер PreferredSizeWidget на основе высоты toolbar
/// и bottom widget
class PreferredAppBarSize extends Size {
  PreferredAppBarSize(this.toolbarHeight, this.bottomHeight)
    : super.fromHeight((toolbarHeight ?? kToolbarHeight) + (bottomHeight ?? 0));

  final double? toolbarHeight;
  final double? bottomHeight;
}

abstract class BasePreferredAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  /// Высота toolbar (по умолчанию kToolbarHeight)
  final double? toolbarHeight;

  /// Bottom widget (например, TabBar)
  final PreferredSizeWidget? bottom;

  const BasePreferredAppBar({super.key, this.toolbarHeight, this.bottom});

  @override
  Size get preferredSize =>
      PreferredAppBarSize(toolbarHeight, bottom?.preferredSize.height);
}
