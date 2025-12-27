import 'package:flutter/material.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppColorsExtension get themeColors => theme.extension<AppColorsExtension>()!;

  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  double get bottomInset => padding.bottom;

  bool get isDarkMode => theme.brightness == Brightness.dark;
}
