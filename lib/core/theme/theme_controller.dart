import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFontSize {
  normal,
  medium,
  large,
  extraLarge,
}

extension AppFontSizeX on AppFontSize {
  double get scale {
    switch (this) {
      case AppFontSize.normal:
        return 1.0;
      case AppFontSize.medium:
        return 1.12;
      case AppFontSize.large:
        return 1.25;
      case AppFontSize.extraLarge:
        return 1.40;
    }
  }

  String get label {
    switch (this) {
      case AppFontSize.normal:
        return 'Normal';
      case AppFontSize.medium:
        return 'Mediana';
      case AppFontSize.large:
        return 'Grande';
      case AppFontSize.extraLarge:
        return 'Muy grande';
    }
  }
}

AppFontSize fontSizeFromAge(int age) {
  if (age >= 70) return AppFontSize.extraLarge;
  if (age >= 60) return AppFontSize.large;
  if (age >= 45) return AppFontSize.medium;
  return AppFontSize.normal;
}

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

final appFontSizeProvider = StateProvider<AppFontSize>((ref) {
  return AppFontSize.normal;
});

final fontScaleProvider = Provider<double>((ref) {
  final fontSize = ref.watch(appFontSizeProvider);
  return fontSize.scale;
});