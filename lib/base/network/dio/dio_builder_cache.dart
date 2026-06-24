import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../common/constants/api_config.dart';
import '../../../common/logger/index.dart';
import 'dio_interceptor.dart';

class DioBuilderCache {
  Dio? _dio;

  Dio getDio() {
    if (_dio != null) return _dio!;

    final baseUrl = dotenv.get('BASE_URL');

    final cacheOptions = CacheOptions(
      policy: CachePolicy.request,
      maxStale: const Duration(days: 1),
      hitCacheOnErrorCodes: [401, 403],
      priority: CachePriority.normal,
      store: null,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          ApiConfig.accept: ApiConfig.applicationAndJson,
          ApiConfig.contentType: ApiConfig.applicationAndJson,
        },
      ),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: false,
        logPrint: (msg) => printDebug(msg),
      ),
      DioInterceptor(),
    ]);

    _dio = dio;
    return dio;
  }
}
