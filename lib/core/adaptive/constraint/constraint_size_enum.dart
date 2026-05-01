enum ConstraintSizeEnum {
  small,
  medium,
  large;

  bool get isSmall => this == ConstraintSizeEnum.small;

  bool get isMedium => this == ConstraintSizeEnum.medium;

  bool get isLarge => this == ConstraintSizeEnum.large;

  T when<T>(T small, {T? medium, T? large}) {
    return switch (this) {
      ConstraintSizeEnum.small => small,
      ConstraintSizeEnum.medium => medium ?? small,
      ConstraintSizeEnum.large => large ?? medium ?? small,
    };
  }

  T? maybeWhen<T>({T? small, T? medium, T? large, T? orElse}) {
    return switch (this) {
      ConstraintSizeEnum.small => small ?? orElse,
      ConstraintSizeEnum.medium => medium ?? orElse,
      ConstraintSizeEnum.large => large ?? orElse,
    };
  }

  T whenBuilder<T>(
    T Function() small, {
    T Function()? medium,
    T Function()? large,
  }) {
    return switch (this) {
      ConstraintSizeEnum.small => small(),
      ConstraintSizeEnum.medium => (medium ?? small)(),
      ConstraintSizeEnum.large => (large ?? medium ?? small)(),
    };
  }

  T? maybeWhenBuilder<T>({
    T Function()? small,
    T Function()? medium,
    T Function()? large,
    T Function()? orElse,
  }) {
    return switch (this) {
      ConstraintSizeEnum.small => (small ?? orElse)?.call(),
      ConstraintSizeEnum.medium => (medium ?? orElse)?.call(),
      ConstraintSizeEnum.large => (large ?? orElse)?.call(),
    };
  }
}
