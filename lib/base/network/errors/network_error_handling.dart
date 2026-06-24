import 'package:dio/dio.dart';

import '../../../injection.dart';
import '../constants/constants.dart';

class ErrorHandling implements Exception {
  String errorMessage = "";
  final Dio dio = getIt<Dio>();

  ErrorHandling.withError({required DioException error}) {
    _handleError(error);
  }

  Future<String> _handleError(DioException error) async {
    String errorMessage = "";
    switch (error.type) {
      case DioExceptionType.cancel:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.unknown:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        errorMessage = "dio_cancel_request";
        break;
      case DioExceptionType.badResponse:
        final int? code = error.response?.statusCode;

        // Handle refresh Token
        // if (code == StatusCode.refreshToken){
        //   await refreshToken(error);
        //   return '';
        // }

        if (code == StatusCode.unauthorized) {
          errorMessage = "unauthorized";
        } else {
          // Todo: Handle message =>
        }
        break;
      default:
        break;
    }
    return errorMessage;
  }

  Future<void> refreshToken(DioException error) async {
    error.requestOptions.cancelToken?.cancel();
    String token = "";
    //get new Token
    final headers = error.requestOptions.headers;
    headers['Authorization'] = token;
    final opts = Options(method: error.requestOptions.method, headers: headers);
    await dio.request(
      error.requestOptions.path,
      options: opts,
      data: error.requestOptions.data,
      queryParameters: error.requestOptions.queryParameters,
    );
  }
}
