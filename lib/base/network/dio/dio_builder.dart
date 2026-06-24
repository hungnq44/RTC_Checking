import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../common/app/index.dart';
import '../../../common/constants/api_config.dart';
import '../../../common/logger/index.dart';
import 'index.dart';

class DioBuilder {
  Dio? dio;

  String baseUrl = AppConfig.baseUrl;

  Dio getDio() {
    if (dio == null) {
      bool canLog = dotenv.get('LOG_DIO', fallback: 'false') == 'true';
      final BaseOptions options = BaseOptions(
        baseUrl: getUrl(),
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(
          seconds: ApiConfig.connectTimeout * 1000,
        ),
        receiveTimeout: const Duration(
          seconds: ApiConfig.receiveTimeout * 1000,
        ),
        headers: {
          ApiConfig.accept: ApiConfig.applicationAndJson,
          ApiConfig.contentType: ApiConfig.applicationAndJson,
        },
      );
      dio = Dio(options);
      dio?.options.headers[ApiConfig.contentType] =
          ApiConfig.applicationAndJson;
      dio?.interceptors.addAll([
        PrettyDioLogger(
          requestHeader: false,
          responseHeader: false,
          requestBody: false,
          responseBody: false,
          request: false,
          logPrint: canLog ? (msg) => printDebug(msg) : (msg) {},
        ),
        DioInterceptor(),
      ]);
    }
    return dio!;
  }

  String getUrl() {
    String url = '';
    try {
      url = dotenv.get('BASE_URL');
    } catch (e) {
      url = baseUrl;
    }
    return url;
  }
}
