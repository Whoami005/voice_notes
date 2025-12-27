import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';

class AppSpacer extends StatelessWidget {
  final double size;

  const AppSpacer._(this.size);

  static const p0 = AppSpacer._(AppSizes.p0);
  static const p2 = AppSpacer._(AppSizes.p2);
  static const p4 = AppSpacer._(AppSizes.p4);
  static const p6 = AppSpacer._(AppSizes.p6);
  static const p8 = AppSpacer._(AppSizes.p8);
  static const p10 = AppSpacer._(AppSizes.p10);
  static const p12 = AppSpacer._(AppSizes.p12);
  static const p14 = AppSpacer._(AppSizes.p14);
  static const p16 = AppSpacer._(AppSizes.p16);
  static const p20 = AppSpacer._(AppSizes.p20);
  static const p24 = AppSpacer._(AppSizes.p24);
  static const p32 = AppSpacer._(AppSizes.p32);
  static const p40 = AppSpacer._(AppSizes.p40);
  static const p48 = AppSpacer._(AppSizes.p48);
  static const p56 = AppSpacer._(AppSizes.p56);
  static const p64 = AppSpacer._(AppSizes.p64);

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
