// lib/features/shared/hot_stamp_production/widgets/hot_stamp_production_delete_dialog.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/hot_stamp_production_model.dart';

class HotStampProductionDeleteDialog extends StatefulWidget {
  final HotStampProduction header;

  /// Parent yang menutup dialog; komponen ini tidak memanggil Navigator.pop.
  final Future<void> Function() onConfirm;

  const HotStampProductionDeleteDialog({
    super.key,
    required this.header,
    required this.onConfirm,
  });

  @override
  State<HotStampProductionDeleteDialog> createState() =>
      _HotStampProductionDeleteDialogState();
}

class _HotStampProductionDeleteDialogState
    extends State<HotStampProductionDeleteDialog> {
  bool _agree = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: _WarningBanner(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ringkasan item
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'NoHotStamp',
                  value: widget.header.noProduksi,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Mesin',
                  value: widget.header.namaMesin,
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Operator',
                  value: widget.header.namaOperator.isNotEmpty
                      ? widget.header.namaOperator
                      : '-',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Tanggal',
                  value: formatDateToFullId(widget.header.tglProduksi),
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Shift',
                  value: 'Shift ${widget.header.shift}',
                ),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Jam Kerja',
                  value: widget.header.hourRangeText.isNotEmpty
                      ? widget.header.hourRangeText
                      : '-',
                ),
                // ✅ Show lock status if locked
                if (widget.header.isLocked) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.header.lockStatusMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Teks utama
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tindakan ini bersifat permanen dan tidak dapat dibatalkan.',
              style: TextStyle(
                color: cs.onSurface.withOpacity(.75),
                height: 1.25,
              ),
            ),
          ),

          // ✅ Warning tambahan jika locked
          if (widget.header.isLocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Produksi ini dalam status terkunci. Pastikan Anda memiliki izin untuk menghapus data yang sudah ditutup.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Checkbox konfirmasi
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _agree,
            onChanged: _submitting
                ? null
                : (v) => setState(() => _agree = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Saya mengerti dan ingin menghapus produksi hot stamp ini.',
              style: TextStyle(color: cs.onSurface.withOpacity(.9)),
            ),
          ),
        ],
      ),
      actions: [
        // Batal
        OutlinedButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('BATAL'),
        ),

        // Hapus (destruktif)
        FilledButton.icon(
          onPressed: (!_agree || _submitting)
              ? null
              : () async {
            setState(() => _submitting = true);
            try {
              await widget.onConfirm(); // parent yang tutup dialog
            } finally {
              if (mounted) {
                setState(() => _submitting = false);
              }
            }
          },
          icon: _submitting
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onError,
            ),
          )
              : const Icon(Icons.delete_outline),
          label: const Text('HAPUS'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            disabledBackgroundColor: cs.error.withOpacity(.4),
            disabledForegroundColor: cs.onError.withOpacity(.8),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 1,
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.error.withOpacity(.95), cs.error.withOpacity(.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: .2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}