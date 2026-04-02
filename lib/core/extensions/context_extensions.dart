import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension BuildContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);

  GoRouter get router => GoRouter.of(this);

  AppColorsExtension get themeColors => theme.extension<AppColorsExtension>()!;

  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  double get bottomInset => padding.bottom;

  double get bottomKeyboardInsets => viewInsets.bottom;

  bool get isDarkMode => theme.brightness == Brightness.dark;
}
