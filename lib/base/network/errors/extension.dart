import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../common/utils/snack_bar_helper.dart';
import '../../../injection.dart';
import '../constants/constants.dart';
import 'network_error.dart';

String _messageFromResponseData(dynamic data) {
  if (data == null) return '';
  if (data is String) {
    final t = data.trim();
    return t.isEmpty ? '' : t;
  }
  if (data is Map) {
    final m =
        data['message'] ??
        data['msg'] ??
        data['Message'] ??
        data['error'] ??
        data['ErrorMessage'];
    if (m != null) return m.toString();
  }
  return '';
}

extension DioErrorMessage on DioException {
  BaseError get baseError {
    BaseError errorMessage = const BaseError.httpUnknownError("unknown");
    switch (type) {
      case DioExceptionType.cancel:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      case DioExceptionType.connectionTimeout:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      case DioExceptionType.unknown:
        final root = error;
        final detail = root == null
            ? ''
            : (root is Exception ? root.toString() : '$root');
        errorMessage = detail.isNotEmpty
            ? BaseError.httpUnknownError(detail)
            : BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        if (statusCode == StatusCode.unauthorized) {
          errorMessage = const BaseError.httpUnAuthorizedError();
        } else {
          final fromBody = _messageFromResponseData(response?.data);
          final fallback = 'HTTP ${statusCode ?? "?"}';
          errorMessage = BaseError.httpInternalServerError(
            fromBody.isNotEmpty ? fromBody : fallback,
          );
        }
        break;
      case DioExceptionType.connectionError:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
      default:
        errorMessage = BaseError.httpUnknownError("dio.cancel_request".tr());
        break;
    }
    return errorMessage;
  }
}

extension BaseErrorMessage on BaseError {
  String get getErrorMessage {
    return when(
      httpInternalServerError: (errorBody) =>
          errorBody.isNotEmpty ? errorBody : 'HttpInternalServerError',
      httpUnAuthorizedError: () => 'HttpUnAuthorizedError',
      httpUnknownError: (message) => message,
    );
  }
}

extension AppMessageExtension on BuildContext {
  void showMessage(String message, {SnackBarType type = SnackBarType.success}) {
    final helper = getIt<SnackBarHelper>();

    switch (type) {
      case SnackBarType.error:
        helper.showError(this, message);
        break;
      case SnackBarType.info:
        helper.showInfo(this, message);
        break;
      default:
        helper.showSuccess(this, message);
        break;
    }
  }
}
