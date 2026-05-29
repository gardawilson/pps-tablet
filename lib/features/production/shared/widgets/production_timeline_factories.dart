import 'package:flutter/material.dart';

import 'production_shift_timeline_dialog.dart';

Widget buildProductionShiftTimelineDialog({
  required String? namaMesin,
  required DateTime tanggal,
  required int shift,
  required String currentNoProduksi,
  required Color primaryColor,
  required Color borderColor,
  required Future<List<ProductionShiftTimelineEntry>> Function() loadTimeline,
  String emptyMessage = 'Tidak ada produksi untuk shift ini.',
}) {
  return ProductionShiftTimelineDialog(
    namaMesin: namaMesin,
    tanggal: tanggal,
    shift: shift,
    currentNoProduksi: currentNoProduksi,
    primaryColor: primaryColor,
    borderColor: borderColor,
    loadTimeline: loadTimeline,
    emptyMessage: emptyMessage,
  );
}
