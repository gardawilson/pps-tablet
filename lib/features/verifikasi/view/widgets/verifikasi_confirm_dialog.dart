// lib/features/verifikasi/view/widgets/verifikasi_confirm_dialog.dart
import 'package:flutter/material.dart';

import '../verifikasi_theme.dart';

/// Dialog konfirmasi sebelum melakukan aksi verifikasi — tanpa kolom
/// catatan (field catatan sudah dihapus untuk semua jenis verifikasi),
/// cukup tampilkan peringatan bahwa aksi ini final. Dipakai bersama oleh
/// dialog Stock Controller, Production Controller, & Kadept — ketiganya
/// modul terpisah yang tidak saling bergantung urutan (kecuali Kadept
/// yang butuh dua-duanya sudah tuntas, dicek di level pemanggil).
Future<bool?> showVerifikasiConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: kVerifikasiWarning),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: kVerifikasiAccent),
          child: const Text('Verifikasi'),
        ),
      ],
    ),
  );
}
