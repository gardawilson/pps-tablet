// lib/core/services/dialog_service.dart
import 'package:flutter/material.dart';
import '../../common/widgets/loading_dialog.dart';
import '../../common/widgets/error_status_dialog.dart';
import '../../common/widgets/success_status_dialog.dart';
import '../navigation/app_nav.dart';

class DialogService {
  DialogService._();
  static final instance = DialogService._();

  int _loadingCount = 0;

  void showLoading({String message = 'Memproses...'}) {
    _loadingCount++;
    if (_loadingCount == 1) {
      final ctx = AppNav.key.currentState!.overlay!.context;
      showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => LoadingDialog(message: message),
      );
    }
  }

  void hideLoading() {
    if (_loadingCount == 0) return;
    _loadingCount--;
    if (_loadingCount == 0) {
      final nav = AppNav.key.currentState!;
      if (nav.canPop()) nav.pop(); // tutup loading
    }
  }

  Future<void> showError({required String title, required String message}) {
    final ctx = AppNav.key.currentState!.overlay!.context;
    return showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => ErrorStatusDialog(title: title, message: message),
    );
  }

// core/services/dialog_service.dart
  Future<void> showSuccess({
    required String title,
    required String message,
    Widget? extra,
    List<StatusAction>? actions,
  }) {
    final ctx = AppNav.key.currentState!.overlay!.context;
    return showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => SuccessStatusDialog(
        title: title,
        message: message,
        extraContent: extra,
        actions: actions,
      ),
    );
  }

}
