import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    colors: AppColorsExtension.dark(),
  );

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    colors: AppColorsExtension.light(),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColorsExtension colors,
  }) {
    final textTheme = _buildTextTheme(colors);

    return ThemeData(
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: colors.bgPrimary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentPrimary,
        onPrimary: colors.textInverse,
        secondary: colors.accentSecondary,
        onSecondary: colors.textInverse,
        error: colors.error,
        onError: colors.textInverse,
        surface: colors.bgSecondary,
        onSurface: colors.textPrimary,
      ),
      extensions: [colors],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgPrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2.copyWith(color: colors.textPrimary),
        iconTheme: IconThemeData(
          color: colors.textPrimary,
          size: AppSizes.iconLarge,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.bgSecondary,
        selectedItemColor: colors.accentPrimary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.micro,
        unselectedLabelStyle: AppTypography.micro,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: colors.textTertiary),
        labelStyle: AppTypography.body.copyWith(color: colors.textSecondary),
        errorStyle: AppTypography.caption.copyWith(color: colors.error),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: colors.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.bottomSheetRadius),
          ),
        ),
        dragHandleColor: colors.borderSecondary,
        dragHandleSize: const Size(AppSizes.handleWidth, AppSizes.handleHeight),
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.accentMuted,
        labelStyle: AppTypography.micro.copyWith(color: colors.accentPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accentPrimary,
        foregroundColor: colors.textInverse,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.fabRadius),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSizes.fabSize,
          height: AppSizes.fabSize,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderPrimary,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: BorderSide(color: colors.borderPrimary),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: AppTypography.body.copyWith(color: colors.textPrimary),
        subtitleTextStyle: AppTypography.caption.copyWith(
          color: colors.textTertiary,
        ),
      ),
      iconTheme: IconThemeData(
        color: colors.textSecondary,
        size: AppSizes.iconMedium,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accentPrimary,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.textInverse,
          textStyle: AppTypography.button,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p12,
          ),
          minimumSize: const Size(0, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p12,
          ),
          minimumSize: const Size(0, AppSizes.buttonHeight),
          side: BorderSide(color: colors.borderSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.bgElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          side: BorderSide(color: colors.borderPrimary),
        ),
        textStyle: AppTypography.body.copyWith(color: colors.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textInverse;
          }
          return colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentPrimary;
          }
          return colors.bgTertiary;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colors.textInverse),
        side: BorderSide(color: colors.borderSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accentPrimary;
          }
          return colors.borderSecondary;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accentPrimary,
        linearTrackColor: colors.bgTertiary,
        circularTrackColor: colors.bgTertiary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accentPrimary,
        inactiveTrackColor: colors.bgTertiary,
        thumbColor: colors.accentPrimary,
        overlayColor: colors.accentMuted,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.accentPrimary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: AppTypography.button,
        unselectedLabelStyle: AppTypography.button,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.accentPrimary, width: 2),
        ),
        dividerColor: colors.borderPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bgElevated,
        contentTextStyle: AppTypography.body.copyWith(
          color: colors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(AppColorsExtension colors) {
    return TextTheme(
      displayLarge: AppTypography.h1Large.copyWith(color: colors.textPrimary),
      displayMedium: AppTypography.h1.copyWith(color: colors.textPrimary),
      displaySmall: AppTypography.h2.copyWith(color: colors.textPrimary),
      headlineMedium: AppTypography.h2.copyWith(color: colors.textPrimary),
      headlineSmall: AppTypography.h3.copyWith(color: colors.textPrimary),
      titleLarge: AppTypography.h3.copyWith(color: colors.textPrimary),
      titleMedium: AppTypography.bodyLarge.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: AppTypography.body.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: colors.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: colors.textPrimary),
      bodySmall: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
      labelLarge: AppTypography.button.copyWith(color: colors.textPrimary),
      labelMedium: AppTypography.caption.copyWith(color: colors.textSecondary),
      labelSmall: AppTypography.micro.copyWith(color: colors.textTertiary),
    );
  }
}
