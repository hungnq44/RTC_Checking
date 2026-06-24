import 'package:dio/dio.dart';

class DioInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final Map<String, dynamic> header = {};

    // 🌐 NGÔN NGỮ (nếu cần)
    header['lang'] = 'vi';

    options.headers.addAll(header);

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ErrorHandling.withError(error: err);
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }
}
