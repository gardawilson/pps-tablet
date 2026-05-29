import 'package:flutter/material.dart';

class ProductionFlowHelpers {
  const ProductionFlowHelpers._();

  static Future<void> openTimeline({
    required BuildContext context,
    required int? idMesin,
    required DateTime? tanggal,
    required VoidCallback onMissingContext,
    required Widget Function(int idMesin, DateTime tanggal) dialogBuilder,
  }) async {
    if (idMesin == null || tanggal == null) {
      onMissingContext();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => dialogBuilder(idMesin, tanggal),
    );
  }

  static Future<void> openSplitAndReplace<TResult>({
    required BuildContext context,
    required int? idMesin,
    required DateTime? tanggal,
    required VoidCallback onMissingContext,
    required Future<TResult?> Function(int idMesin, DateTime tanggal)
    showSplitDialog,
    required void Function() beforeReplace,
    required Future<void> Function(TResult result) replaceToResult,
  }) async {
    if (idMesin == null || tanggal == null) {
      onMissingContext();
      return;
    }
    final result = await showSplitDialog(idMesin, tanggal);
    if (result == null) return;
    beforeReplace();
    await replaceToResult(result);
  }
}
