// Khởi tạo App
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'index.dart';

class AppInitializer {
  static Future<void> init(String envFile) async {
    await dotenv.load(fileName: envFile);
    await AppConfig.load();
  }
}
