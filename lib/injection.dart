import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'base/network/dio/index.dart';
import 'common/app/index.dart';
import 'common/constants/api_config.dart';
import 'common/logger/index.dart';
import 'common/notification/index.dart';
import 'common/services/index.dart';
import 'common/services/location_preference_service.dart';
import 'common/utils/snack_bar_helper.dart';
import 'features/checking/data/datasource/service/checking_service.dart';
import 'features/checking/data/datasource/service/supabase_service.dart';
import 'features/checking/data/repository/checking_repo.dart';
import 'features/checking/data/repository/checking_repo_impl.dart';
import 'features/checking/view/bloc/checking_bloc.dart';

final getIt = GetIt.instance;

void configDependencies() {
  /// ==== NETWORK ====
  getIt.registerLazySingleton<Dio>(() {
    final baseUrl = AppConfig.baseUrl;

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
        headers: const {
          ApiConfig.accept: ApiConfig.applicationAndJson,
          ApiConfig.contentType: ApiConfig.applicationAndJson,
        },
      ),
    );
    if (AppConfig.enableDioLog) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          requestHeader: true,
          responseBody: true,
          responseHeader: true,
          error: true,
        ),
      );
    }
    dio.interceptors.add(DioInterceptor());
    return dio;
  });

  /// ==== COMMON ====
  getIt.registerLazySingleton<LogUtils>(() => LogUtils());

  getIt.registerLazySingleton<SnackBarHelper>(() => SnackBarHelper());

  // ==== SERVICE ====
  getIt.registerLazySingleton<CheckingService>(
    () => CheckingService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<SupabaseService>(
    () => SupabaseService(getIt<LogUtils>()),
  );

  // ==== REPOSITORY ====
  getIt.registerLazySingleton<CheckingRepo>(
    () => CheckingRepoImpl(getIt<CheckingService>(), getIt<SupabaseService>()),
  );

  // ==== NOTIFICATION ====
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<LogUtils>()),
  );

  // ==== LOCATION SERVICE ====
  getIt.registerLazySingleton<LocationServiceManager>(
    () => LocationServiceManager(getIt<LogUtils>()),
  );

  // ==== BLOC ====
  getIt.registerFactory<CheckingBloc>(
    () => CheckingBloc(
      getIt<LogUtils>(),
      getIt<CheckingRepo>(),
      getIt<NotificationService>(),
      getIt<LocationServiceManager>(),
      getIt<LocationPreferenceService>(),
    ),
  );
}
