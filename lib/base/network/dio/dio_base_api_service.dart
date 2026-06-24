import 'package:dio/dio.dart';

abstract class DioBaseApiService {
  final Dio dio;

  DioBaseApiService(this.dio);

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    T Function(dynamic json)? parser,
  }) async {
    final res = await dio.get(path, queryParameters: query, options: options);
    return parser != null ? parser(res.data) : res.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Options? options,
    T Function(dynamic json)? parser,
  }) async {
    final res = await dio.post(
      path,
      data: body,
      queryParameters: query,
      options: options,
    );
    return parser != null ? parser(res.data) : res.data as T;
  }

  Future<T> put<T>(
    String path, {
    dynamic body,
    Options? options,
    T Function(dynamic json)? parser,
  }) async {
    final res = await dio.put(path, data: body, options: options);
    return parser != null ? parser(res.data) : res.data as T;
  }

  Future<T> delete<T>(
    String path, {
    dynamic body,
    Options? options,
    T Function(dynamic json)? parser,
  }) async {
    final res = await dio.delete(path, data: body, options: options);
    return parser != null ? parser(res.data) : res.data as T;
  }
}
