import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

enum SnackBarType { success, error, info }

@singleton
class SnackBarHelper {
  void _show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.success,
    int duration = 1,
    Function()? onTap,
  }) {
    Widget snackBar;

    switch (type) {
      case SnackBarType.success:
        snackBar = CustomSnackBar.success(message: message);
        break;

      case SnackBarType.error:
        snackBar = CustomSnackBar.error(message: message);
        break;

      case SnackBarType.info:
        snackBar = CustomSnackBar.info(message: message);
        break;
    }

    showTopSnackBar(
      Overlay.of(context),
      snackBar,
      displayDuration: Duration(seconds: duration),
      onTap: onTap,
    );
  }

  dynamic showSuccess(
    BuildContext context,
    String message, {
    Function()? onTap,
  }) => _show(context, message, onTap: onTap);

  dynamic showInfo(BuildContext context, String message, {Function()? onTap}) =>
      _show(context, message, onTap: onTap, type: SnackBarType.info);

  dynamic showError(BuildContext context, String message) =>
      _show(context, message, type: SnackBarType.error);
}
