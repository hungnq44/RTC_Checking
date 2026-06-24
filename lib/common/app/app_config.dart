// Cấu hình App
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'index.dart';

class AppConfig {
  AppConfig._();

  static late AppEnv env;
  static late String baseUrl;
  static late bool enableDioLog;
  static late String appName;

  static bool get isDebug => env == AppEnv.debug;

  static bool get isProduction => env == AppEnv.production;

  static bool get isStaging => env == AppEnv.staging;

  static Future<void> load() async {
    final envStr = dotenv.env['ENV'] ?? dotenv.env['APP_ENV'] ?? 'debug';

    env = AppEnv.fromString(envStr);
    baseUrl = dotenv.env['BASE_URL'] ?? '';
    enableDioLog = dotenv.env['ENABLE_DIO_LOG'] == 'true';
    appName = dotenv.env['APP_NAME'] ?? '';
  }
}
