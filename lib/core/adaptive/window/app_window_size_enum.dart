import 'package:flutter/widgets.dart';

enum AppWindowSizeEnum {
  compact(maxWidth: 600),
  medium(maxWidth: 840),
  expanded(maxWidth: 1200),
  large(maxWidth: double.maxFinite);

  const AppWindowSizeEnum({required this.maxWidth});

  final double maxWidth;

  bool get isCompact => this == AppWindowSizeEnum.compact;

  bool get isMedium => this == AppWindowSizeEnum.medium;

  bool get isExpanded => this == AppWindowSizeEnum.expanded;

  bool get isLarge => this == AppWindowSizeEnum.large;

  bool get isCompactOnly => isCompact;

  bool get isMediumOrLarger => !isCompact;

  bool get isExpandedOrLarger => isExpanded || isLarge;

  static AppWindowSizeEnum fromContext(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return fromWidth(width);
  }

  static AppWindowSizeEnum fromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return AppWindowSizeEnum.large;

    return fromWidth(constraints.maxWidth);
  }

  static AppWindowSizeEnum fromWidth(double width) {
    assert(width >= 0, 'width must be non-negative');

    if (width <= AppWindowSizeEnum.compact.maxWidth) {
      return AppWindowSizeEnum.compact;
    }
    if (width <= AppWindowSizeEnum.medium.maxWidth) {
      return AppWindowSizeEnum.medium;
    }
    if (width <= AppWindowSizeEnum.expanded.maxWidth) {
      return AppWindowSizeEnum.expanded;
    }

    return AppWindowSizeEnum.large;
  }

  T when<T>(T compact, {T? medium, T? expanded, T? large}) {
    return switch (this) {
      AppWindowSizeEnum.compact => compact,
      AppWindowSizeEnum.medium => medium ?? compact,
      AppWindowSizeEnum.expanded => expanded ?? medium ?? compact,
      AppWindowSizeEnum.large => large ?? expanded ?? medium ?? compact,
    };
  }

  T? maybeWhen<T>({T? compact, T? medium, T? expanded, T? large, T? orElse}) {
    return switch (this) {
      AppWindowSizeEnum.compact => compact ?? orElse,
      AppWindowSizeEnum.medium => medium ?? orElse,
      AppWindowSizeEnum.expanded => expanded ?? orElse,
      AppWindowSizeEnum.large => large ?? orElse,
    };
  }

  T whenBuilder<T>(
    T Function() compact, {
    T Function()? medium,
    T Function()? expanded,
    T Function()? large,
  }) {
    return switch (this) {
      AppWindowSizeEnum.compact => compact(),
      AppWindowSizeEnum.medium => (medium ?? compact)(),
      AppWindowSizeEnum.expanded => (expanded ?? medium ?? compact)(),
      AppWindowSizeEnum.large => (large ?? expanded ?? medium ?? compact)(),
    };
  }

  T? maybeWhenBuilder<T>({
    T Function()? compact,
    T Function()? medium,
    T Function()? expanded,
    T Function()? large,
    T Function()? orElse,
  }) {
    return switch (this) {
      AppWindowSizeEnum.compact => (compact ?? orElse)?.call(),
      AppWindowSizeEnum.medium => (medium ?? orElse)?.call(),
      AppWindowSizeEnum.expanded => (expanded ?? orElse)?.call(),
      AppWindowSizeEnum.large => (large ?? orElse)?.call(),
    };
  }
}

extension AppWindowSizeBuildContextExtension on BuildContext {
  AppWindowSizeEnum get windowSize => AppWindowSizeEnum.fromContext(this);
}

extension AppWindowSizeConstraintsExtension on BoxConstraints {
  AppWindowSizeEnum get windowSize => AppWindowSizeEnum.fromConstraints(this);
}
