// Các log thường sử dụng cho App
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@singleton
class LogUtils {
  /// methodCount:2 , // number of method calls to be displayed
  /// errorMethodCount: 8, // number of method calls if stacktrace is provided
  /// lineLength: 120, // width of the output
  /// colors: true, // Colorful log messages
  /// printEmojis: true, // Print an emoji for each log message
  /// printTime: false, // Should each log print contain a timestamp
  final bool showLog = kDebugMode;
  // final bool showLog = kDebugMode && kReleaseMode; //For test notification

  final _logger = Logger(
    printer: PrettyPrinter(
      colors: false,
      printEmojis: true,
      methodCount: 0, // 🔥 TẮT stacktrace
      errorMethodCount: 0, // 🔥 TẮT stacktrace cho error
    ),
  );

  void debugNormal(String text) {
    if (showLog) {
      // ignore: avoid_print
      print("==========================================================");
      // ignore: avoid_print
      print("Logs Debug: $text");
      // ignore: avoid_print
      print("==========================================================");
    }
  }

  void logT(String text) {
    if (showLog) _logger.t(text);
  }

  void logD(String text) {
    if (showLog) _logger.d(text);
  }

  void logI(String text) {
    if (showLog) _logger.i(text);
  }

  void logW(String text) {
    if (showLog) _logger.w(text);
  }

  void logE(String text) {
    if (showLog) _logger.e(text);
  }

  void logF(String text) {
    if (showLog) _logger.f(text);
  }
}
