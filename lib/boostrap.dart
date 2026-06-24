import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'base/bloc/app_bloc_observer.dart';
import 'common/app/app_initializer.dart';
import 'common/notification/index.dart';
import 'common/services/location_preference_service.dart';
import 'injection.dart';

Future<void> bootstrap(String envFile) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await AppInitializer.init(envFile);

    // Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      if (kDebugMode) {
        debugPrint('=== Supabase initialized successfully ===');
        debugPrint('URL: $supabaseUrl');
      }
    } else {
      if (kDebugMode) {
        debugPrint('=== Supabase NOT initialized: missing URL or ANON_KEY ===');
      }
    }

    configDependencies();

    // Initialize SharedPreferences and register service
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<LocationPreferenceService>(LocationPreferenceService(prefs));

    Bloc.observer = const AppBlocObserver();
    await EasyLocalization.ensureInitialized();

    await getIt<NotificationService>().init();

    String ACCESS_TOKEN = dotenv.env['ACCESS_TOKEN'] ?? '';
    MapboxOptions.setAccessToken(ACCESS_TOKEN);

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        path: 'assets/translate',
        fallbackLocale: const Locale('vi', 'VN'),
        child: const App(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('=== BOOTSTRAP ERROR ===');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    rethrow;
  } finally {
    FlutterNativeSplash.remove();
  }
}
