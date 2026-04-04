import 'package:flutter/material.dart';
import 'package:voice_notes/core/theme/app_colors.dart';

/// Гибкий виджет плитки списка с полным контролем над размерами.
class FlexibleListTile extends StatelessWidget {
  /// Виджет слева (аватар, иконка и т.д.)
  final Widget? leading;

  /// Основной заголовок
  final Widget? title;

  /// Подзаголовок под title
  final Widget? subtitle;

  /// Виджет справа (иконка, кнопка и т.д.)
  final Widget? trailing;

  /// Фиксированная высота плитки
  /// Если не указана, высота определяется контентом
  final double? height;

  /// Минимальная высота плитки
  final double? minHeight;

  /// Максимальная высота плитки
  final double? maxHeight;

  /// Внутренние отступы
  /// По умолчанию: EdgeInsets.symmetric(horizontal: 16, vertical: 8)
  final EdgeInsetsGeometry? contentPadding;

  /// Горизонтальный промежуток между элементами
  /// По умолчанию: 16
  final double? horizontalGap;

  final double? verticalGap;

  /// Вертикальное выравнивание элементов
  /// По умолчанию: CrossAxisAlignment.center
  final CrossAxisAlignment verticalAlignment;

  /// Цвет фона
  final Color? backgroundColor;

  /// Цвет фона при selected = true
  final Color? selectedColor;

  /// Цвет splash эффекта при нажатии
  final Color? splashColor;

  /// Цвет при наведении курсора
  final Color? hoverColor;

  /// Форма плитки (приоритетнее чем borderRadius)
  final ShapeBorder? shape;

  /// Скругление углов
  final BorderRadiusGeometry? borderRadius;

  /// Граница плитки
  final BoxBorder? border;

  /// Высота тени
  final double elevation;

  /// Цвет тени
  final Color? shadowColor;

  /// Обработчик нажатия
  final VoidCallback? onTap;

  /// Обработчик долгого нажатия
  final VoidCallback? onLongPress;

  /// Обработчик двойного нажатия
  final VoidCallback? onDoubleTap;

  /// Активна ли плитка
  final bool enabled;

  /// Выбрана ли плитка
  final bool selected;

  /// Компактный режим (меньше отступы)
  final bool dense;

  /// Курсор мыши
  final MouseCursor? mouseCursor;

  /// Focus node для управления фокусом
  final FocusNode? focusNode;

  /// Автофокус при построении
  final bool autofocus;

  /// Семантическая метка для accessibility
  final String? semanticLabel;

  const FlexibleListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.contentPadding,
    this.horizontalGap,
    this.verticalAlignment = CrossAxisAlignment.center,
    this.backgroundColor,
    this.selectedColor,
    this.splashColor,
    this.hoverColor,
    this.shape,
    this.borderRadius,
    this.border,
    this.elevation = 0,
    this.shadowColor,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.mouseCursor,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.verticalGap,
  });

  EdgeInsetsGeometry get _effectivePadding {
    if (contentPadding != null) return contentPadding!;
    return EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 4 : 8);
  }

  double get _effectiveGap => horizontalGap ?? (dense ? 12 : 16);

  double get _effectiveVerticalGap => verticalGap ?? (dense ? 2 : 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listTileTheme = ListTileTheme.of(context);

    final effectiveBackgroundColor = selected
        ? (selectedColor ?? theme.colorScheme.primaryContainer)
        : (backgroundColor ?? listTileTheme.tileColor ?? AppColors.transparent);

    final effectiveShape =
        shape ??
        (borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius!)
            : null);

    Widget content = Padding(
      padding: _effectivePadding,
      child: Row(
        crossAxisAlignment: verticalAlignment,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: _effectiveGap)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title != null)
                  DefaultTextStyle(
                    style: _titleStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                if (subtitle != null) ...[
                  SizedBox(height: _effectiveVerticalGap),
                  DefaultTextStyle(
                    style: _subtitleStyle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: _effectiveGap), trailing!],
        ],
      ),
    );

    // Применяем ограничения высоты
    if (height != null || minHeight != null || maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height ?? minHeight ?? 0,
          maxHeight: height ?? maxHeight ?? double.infinity,
        ),
        child: height != null
            ? SizedBox(height: height, child: content)
            : content,
      );
    }

    // Оборачиваем в Material для ink эффектов
    Widget tile = Material(
      color: effectiveBackgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: effectiveShape,
      borderRadius: effectiveShape == null ? borderRadius : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        onDoubleTap: enabled ? onDoubleTap : null,
        splashColor: splashColor,
        hoverColor: hoverColor,
        mouseCursor:
            mouseCursor ??
            (enabled
                ? (onTap != null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic)
                : SystemMouseCursors.forbidden),
        focusNode: focusNode,
        autofocus: autofocus,
        customBorder: effectiveShape,
        borderRadius: effectiveShape == null
            ? borderRadius as BorderRadius?
            : null,
        child: Opacity(opacity: enabled ? 1.0 : 0.5, child: content),
      ),
    );

    // Добавляем border если указан
    if (border != null) {
      tile = DecoratedBox(
        decoration: BoxDecoration(border: border, borderRadius: borderRadius),
        child: tile,
      );
    }

    // Добавляем семантику
    if (semanticLabel != null) {
      tile = Semantics(
        label: semanticLabel,
        button: onTap != null,
        enabled: enabled,
        selected: selected,
        child: tile,
      );
    }

    return tile;
  }

  TextStyle _titleStyle(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge ?? const TextStyle();

    return baseStyle.copyWith(
      fontSize: dense ? 14 : 16,
      fontWeight: FontWeight.w500,
      color: enabled
          ? (selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }

  TextStyle _subtitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    return baseStyle.copyWith(
      fontSize: dense ? 12 : 14,
      color: enabled
          ? (selected
                ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                : theme.colorScheme.onSurfaceVariant)
          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }
}
