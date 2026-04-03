import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

abstract final class AppToast {
  static const _autoCloseDuration = Duration(seconds: 4);

  static void error(BuildContext context, {required String message}) {
    _show(
      context: context,
      type: ToastificationType.error,
      primaryColor: context.themeColors.error,
      message: message,
    );
  }

  static void success(BuildContext context, {required String message}) {
    _show(
      context: context,
      type: ToastificationType.success,
      primaryColor: context.themeColors.success,
      message: message,
    );
  }

  static void warning(BuildContext context, {required String message}) {
    _show(
      context: context,
      type: ToastificationType.warning,
      primaryColor: context.themeColors.warning,
      message: message,
    );
  }

  static void info(BuildContext context, {required String message}) {
    _show(
      context: context,
      type: ToastificationType.info,
      primaryColor: context.themeColors.info,
      message: message,
    );
  }

  static void _show({
    required BuildContext context,
    required ToastificationType type,
    required Color primaryColor,
    required String message,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      title: Text(message, maxLines: 5),
      alignment: Alignment.topCenter,
      autoCloseDuration: _autoCloseDuration,
      primaryColor: primaryColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      showProgressBar: false,
      dragToClose: true,
      pauseOnHover: true,
    );
  }
}
