// lib/features/production/inject/widgets/inject_validate_label_dialog.dart

import 'package:flutter/material.dart';

import '../model/inject_validate_label_model.dart';

/// Dialog yang tampil saat label tidak sesuai formula.
class InjectValidateLabelDialog extends StatelessWidget {
  final InjectValidateLabelResult result;

  const InjectValidateLabelDialog({super.key, required this.result});

  static Future<void> show(
    BuildContext context,
    InjectValidateLabelResult result,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) => InjectValidateLabelDialog(result: result),
      );

  String _formatCategory(String? kode) {
    if (kode == null) return 'Output';
    switch (kode.toLowerCase()) {
      case 'barangjadi':
        return 'Barang Jadi';
      case 'furniturewip':
        return 'Furniture WIP';
      default:
        return kode;
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFB71C1C);
    const redLight = Color(0xFFFFEBEE);
    const amber = Color(0xFF7B4600);
    const amberLight = Color(0xFFFFF8E1);
    const border = Color(0xFFE2E6EA);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: redLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Label Tidak Valid',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: red,
                          ),
                        ),
                        Text(
                          result.labelCode,
                          style: TextStyle(
                            fontSize: 12,
                            color: red.withValues(alpha: 0.75),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    color: red,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alasan
                  if (result.reason != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: amberLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.reason!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Info label yang di-scan
                  if (result.labelNamaJenis != null) ...[
                    const Text(
                      'LABEL YANG DI-SCAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF90A4AE),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result.labelPrefix ?? '-',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0277BD),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result.labelNamaJenis!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Output produksi ini
                  if (result.outputs.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'OUTPUT PRODUKSI INI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF90A4AE),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatCategory(result.outputCategory),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...result.outputs.asMap().entries.map((e) {
                      final idx = e.key;
                      final out = e.value;
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: idx < result.outputs.length - 1 ? 6 : 0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(
                                  color: Color(0xFF00695C), width: 3),
                              top: BorderSide(color: border),
                              right: BorderSide(color: border),
                              bottom: BorderSide(color: border),
                            ),
                          ),
                          child: Text(
                            out.namaJenis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
