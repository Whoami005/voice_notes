import 'package:flutter/material.dart';

/// Универсальный виджет для условного отображения.
///
/// Поддерживает несколько режимов работы через разные конструкторы:
///
/// 1. Базовый - выбор между двумя виджетами:
/// ```dart
/// ConditionalChild(
///   condition: isLoggedIn,
///   onTrue: const UserProfile(),
///   onFalse: const LoginButton(),
/// )
/// ```
///
/// 2. Builder - ленивое создание виджетов:
/// ```dart
/// ConditionalChild.builder(
///   condition: showDetails,
///   onTrue: (context) => HeavyWidget(theme: Theme.of(context)),
///   onFalse: (context) => const LightWidget(),
/// )
/// ```
///
/// 3. Показать только при true:
/// ```dart
/// ConditionalChild.ifTrue(
///   condition: hasNotification,
///   child: const NotificationBadge(),
/// )
/// ```
///
/// 4. Показать только при false:
/// ```dart
/// ConditionalChild.ifFalse(
///   condition: isLoading,
///   child: const ContentWidget(),
/// )
/// ```
class ConditionalChild extends StatelessWidget {
  /// Условие для выбора отображаемого виджета.
  final bool condition;

  final Widget? _onTrue;
  final Widget? _onFalse;
  final WidgetBuilder? _onTrueBuilder;
  final WidgetBuilder? _onFalseBuilder;

  /// Базовый конструктор - выбор между двумя виджетами.
  const ConditionalChild({
    required this.condition,
    required Widget onTrue,
    required Widget onFalse,
    super.key,
  }) : _onTrue = onTrue,
       _onFalse = onFalse,
       _onTrueBuilder = null,
       _onFalseBuilder = null;

  /// Конструктор с builders для ленивого создания виджетов.
  ///
  /// Используйте когда виджеты "тяжёлые" и создавать оба нецелесообразно.
  const ConditionalChild.builder({
    required this.condition,
    required WidgetBuilder onTrue,
    required WidgetBuilder onFalse,
    super.key,
  }) : _onTrueBuilder = onTrue,
       _onFalseBuilder = onFalse,
       _onTrue = null,
       _onFalse = null;

  /// Показать [child] только когда [condition] == true.
  ///
  /// При false возвращает пустой SizedBox.shrink().
  const ConditionalChild.ifTrue({
    required this.condition,
    required Widget child,
    super.key,
  }) : _onTrue = child,
       _onFalse = null,
       _onTrueBuilder = null,
       _onFalseBuilder = null;

  /// Показать [child] только когда [condition] == false.
  ///
  /// При true возвращает пустой SizedBox.shrink().
  const ConditionalChild.ifFalse({
    required this.condition,
    required Widget child,
    super.key,
  }) : _onFalse = child,
       _onTrue = null,
       _onTrueBuilder = null,
       _onFalseBuilder = null;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return _onTrueBuilder?.call(context) ??
          _onTrue ??
          const SizedBox.shrink();
    }

    return _onFalseBuilder?.call(context) ??
        _onFalse ??
        const SizedBox.shrink();
  }
}
