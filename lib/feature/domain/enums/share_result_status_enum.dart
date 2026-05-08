enum ShareResultStatusEnum {
  success,
  dismissed,
  unavailable;

  bool get isSuccess => this == ShareResultStatusEnum.success;

  bool get isDismissed => this == ShareResultStatusEnum.dismissed;

  bool get isUnavailable => this == ShareResultStatusEnum.unavailable;
}
