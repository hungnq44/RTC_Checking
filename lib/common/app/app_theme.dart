// Màu chủ đề App
import 'package:flutter/material.dart';

import 'index.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor()),
    );
  }

  static Color seedColor() {
    switch (AppConfig.env) {
      case AppEnv.debug:
        return Colors.blue;
      case AppEnv.production:
        return Colors.red;
      case AppEnv.staging:
        return Colors.green;
    }
  }
}
