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
    return fromDimension(MediaQuery.sizeOf(context).width);
  }

  static AppWindowSizeEnum fromConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return AppWindowSizeEnum.large;

    return fromDimension(constraints.maxWidth);
  }

  static AppWindowSizeEnum fromDimension(double dimension) {
    assert(dimension >= 0, 'dimension must be non-negative');

    if (dimension <= AppWindowSizeEnum.compact.maxWidth) {
      return AppWindowSizeEnum.compact;
    }
    if (dimension <= AppWindowSizeEnum.medium.maxWidth) {
      return AppWindowSizeEnum.medium;
    }
    if (dimension <= AppWindowSizeEnum.expanded.maxWidth) {
      return AppWindowSizeEnum.expanded;
    }

    return AppWindowSizeEnum.large;
  }

  static AppWindowSizeEnum fromWidth(double width) => fromDimension(width);

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
  AppWindowSizeEnum get windowWidthSize => AppWindowSizeEnum.fromContext(this);
}

extension AppWindowSizeConstraintsExtension on BoxConstraints {
  AppWindowSizeEnum get windowWidthSize =>
      AppWindowSizeEnum.fromConstraints(this);
}
