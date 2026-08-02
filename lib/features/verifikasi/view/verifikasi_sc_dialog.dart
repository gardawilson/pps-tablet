// lib/features/verifikasi/view/verifikasi_sc_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/error_status_dialog.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../services/verifikasi_notification_manager.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_theme.dart';
import 'widgets/reconciliation_section.dart';
import 'widgets/verifikasi_confirm_dialog.dart';

/// Dialog verifikasi Stock Controller (badge "SC") — cross-check input vs
/// output untuk satu NoProduksi. Modul verifikasi yang berdiri sendiri: bisa
/// diisi kapan pun tanpa menunggu verifikasi Production Controller (lihat
/// [showVerifikasiPcDialog] di `verifikasi_pc_dialog.dart`) — keduanya tidak
/// saling bergantung urutan. Hanya verifikasi Kadept (department) yang butuh
/// keduanya sudah tuntas (lihat `verifikasi_kd_dialog.dart`).
///
/// [vm] harus di-pass eksplisit karena dialog di-inject ke Overlay Navigator
/// (bukan child dari widget tree pemanggil), jadi tidak bisa mengandalkan
/// context.read/watch langsung tanpa provider baru.
Future<void> showVerifikasiScDialog(
  BuildContext context, {
  required VerifikasiViewModel vm,
  required VerifikasiItem item,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider<VerifikasiViewModel>.value(
      value: vm,
      child: VerifikasiScDialog(item: item),
    ),
  );
}

class VerifikasiScDialog extends StatefulWidget {
  final VerifikasiItem item;

  const VerifikasiScDialog({super.key, required this.item});

  @override
  State<VerifikasiScDialog> createState() => _VerifikasiScDialogState();
}

class _VerifikasiScDialogState extends State<VerifikasiScDialog> {
  late Future<ProductionCrossCheckSummary> _future;

  @override
  void initState() {
    super.initState();
    final vm = context.read<VerifikasiViewModel>();
    _future = vm.fetchCrossCheck(widget.item);
  }

  Future<void> _handleVerify() async {
    final confirmed = await showVerifikasiConfirmDialog(
      context,
      title: 'Verifikasi Stock Controller?',
      message:
          'Konfirmasi bahwa input & output untuk ${widget.item.noProduksi} sudah dicek dan sesuai. Tindakan ini tidak bisa dibatalkan.',
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<VerifikasiViewModel>();
    final notifMgr = context.read<VerifikasiNotificationManager>();
    final ok = await vm.verify(widget.item);
    if (!mounted) return;

    if (ok) {
      notifMgr.markVerified(widget.item.jenisKey, widget.item.noProduksi);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Produksi berhasil diverifikasi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Verifikasi',
          message: vm.actionError ?? 'Kesalahan tidak diketahui',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tgl = item.tglProduksi != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(item.tglProduksi!.toLocal())
        : '-';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderStrip(item, tgl),
            const Divider(height: 1, color: kVerifikasiBorder),
            Flexible(
              child: FutureBuilder<ProductionCrossCheckSummary>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat data:\n${snapshot.error}'),
                    );
                  }
                  return SingleChildScrollView(
                    child: ReconciliationSection(summary: snapshot.data!),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: kVerifikasiBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kVerifikasiMuted,
                        side: const BorderSide(color: kVerifikasiBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Builder(
                      builder: (context) {
                        final canVerify = context
                            .watch<PermissionViewModel>()
                            .can('produksi_washing:read');
                        final alreadyVerified = widget.item.verified;
                        return FilledButton.icon(
                          onPressed: (canVerify && !alreadyVerified)
                              ? _handleVerify
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: kVerifikasiAccent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            alreadyVerified
                                ? 'Sudah Diverifikasi Stock Controller'
                                : 'Verifikasi Stock Controller',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: grid label-value dense, bukan kartu ────────────────────────────
  Widget _buildHeaderStrip(VerifikasiItem item, String tgl) {
    final hasJam =
        (item.hourStart ?? '').isNotEmpty || (item.hourEnd ?? '').isNotEmpty;
    final jam = hasJam
        ? '${item.hourStart ?? '-'} - ${item.hourEnd ?? '-'}'
        : '-';

    return Container(
      color: kVerifikasiSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERIFIKASI STOCK CONTROLLER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: kVerifikasiAccent,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerField('NO PRODUKSI', item.noProduksi, emphasize: true),
              _headerField('MESIN', item.namaMesin ?? '-'),
              _headerField('TANGGAL', tgl),
              _headerField('SHIFT', '${item.shift ?? '-'}'),
              _headerField('JAM', jam),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 18, color: kVerifikasiMuted),
                tooltip: 'Tutup',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerField(String label, String value, {bool emphasize = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: kVerifikasiMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: emphasize ? 14 : 12.5,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: kVerifikasiInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
