// lib/features/verifikasi/view/verifikasi_kd_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/error_status_dialog.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../model/verifikasi_operator_summary_model.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_theme.dart';
import 'widgets/reconciliation_section.dart';
import 'widgets/verifikasi_confirm_dialog.dart';

/// Dialog verifikasi Kadept (Kepala Department, badge "KD") untuk satu
/// NoProduksi — berlaku lintas jenis produksi (washing, broker, dst) selama
/// [VerifikasiAdapter.hasDepartmentVerification] jenis tsb true. Gabungan
/// detail dari verifikasi Stock Controller & Production Controller. Beda
/// dengan dua modul verifikasi lain ([showVerifikasiScDialog] &
/// [showVerifikasiPcDialog]) yang independen satu sama lain, dialog
/// ini BUTUH keduanya sudah tuntas ([item.verified] & [item.verifiedOperator]
/// sama-sama true) — dijamin lewat tombol yang disabled di list
/// ([verifikasi_list_screen.dart]), dan dicek ulang di sini sebagai
/// pengaman kedua.
Future<void> showVerifikasiKdDialog(
  BuildContext context, {
  required VerifikasiViewModel vm,
  required VerifikasiItem item,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider<VerifikasiViewModel>.value(
      value: vm,
      child: VerifikasiKdDialog(item: item),
    ),
  );
}

class VerifikasiKdDialog extends StatefulWidget {
  final VerifikasiItem item;

  const VerifikasiKdDialog({super.key, required this.item});

  @override
  State<VerifikasiKdDialog> createState() => _VerifikasiKdDialogState();
}

class _KdDialogData {
  final VerifikasiOperatorHeader header;
  final ProductionCrossCheckSummary crossCheck;

  const _KdDialogData({required this.header, required this.crossCheck});
}

class _VerifikasiKdDialogState extends State<VerifikasiKdDialog> {
  late Future<_KdDialogData> _future;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<VerifikasiViewModel>();
    _future = _load(vm);
  }

  Future<_KdDialogData> _load(VerifikasiViewModel vm) async {
    final results = await Future.wait([
      vm.fetchOperatorHeader(widget.item),
      vm.fetchCrossCheck(widget.item),
    ]);
    return _KdDialogData(
      header: results[0] as VerifikasiOperatorHeader,
      crossCheck: results[1] as ProductionCrossCheckSummary,
    );
  }

  Future<void> _handleVerify() async {
    final confirmed = await showVerifikasiConfirmDialog(
      context,
      title: 'Verifikasi Kadept?',
      message:
          'Konfirmasi final untuk ${widget.item.noProduksi} — seluruh data '
          'Stock Controller & Production Controller sudah dicek dan sesuai. Tindakan ini tidak bisa dibatalkan.',
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    final vm = context.read<VerifikasiViewModel>();
    final ok = await vm.verifyDepartmentStage(widget.item);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Verifikasi Kadept berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isActing = false);
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
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 660),
        child: FutureBuilder<_KdDialogData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat data:\n${snapshot.error}'),
                ),
              );
            }

            final data = snapshot.data!;
            final h = data.header;
            final notReady = !h.verified || !h.verifiedOperator;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderStrip(h),
                if (notReady) _buildNotReadyNotice(h),
                const Divider(height: 1, color: kVerifikasiBorder),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOperatorPanel(h),
                        const Divider(height: 1, color: kVerifikasiBorder),
                        // Detail penuh per label — gabungan data kepala
                        // stok & operator supaya department bisa lihat
                        // semuanya sebelum verifikasi final.
                        ReconciliationSection(summary: data.crossCheck),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: kVerifikasiBorder),
                _buildFooter(h, notReady: notReady),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Notice: Stock Controller & Production Controller harus tuntas dulu ───
  Widget _buildNotReadyNotice(VerifikasiOperatorHeader h) {
    final missing = [
      if (!h.verified) 'Stock Controller',
      if (!h.verifiedOperator) 'Production Controller',
    ].join(' & ');

    return Container(
      width: double.infinity,
      color: kVerifikasiWarningBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: kVerifikasiWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verifikasi $missing belum tuntas — verifikasi Kadept '
              'belum bisa dilakukan.',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: kVerifikasiWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: grid label-value dense, sama gaya dengan dialog lain ─────────
  Widget _buildHeaderStrip(VerifikasiOperatorHeader h) {
    final tgl = h.tglProduksi != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(h.tglProduksi!.toLocal())
        : '-';
    final hasJam = (h.hourStart ?? '').isNotEmpty || (h.hourEnd ?? '').isNotEmpty;
    final jam = hasJam ? '${h.hourStart ?? '-'} - ${h.hourEnd ?? '-'}' : '-';

    return Container(
      color: kVerifikasiSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VERIFIKASI KADEPT',
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
              _headerField('NO PRODUKSI', h.noProduksi, emphasize: true),
              _headerField('MESIN', h.namaMesin ?? '-'),
              _headerField('TANGGAL', tgl),
              _headerField('SHIFT', '${h.shift ?? '-'}'),
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

  // ── Panel: info penugasan operator, regu & kehadiran ──────────────────────
  Widget _buildOperatorPanel(VerifikasiOperatorHeader h) {
    final namaOperatorList = h.operators.isNotEmpty
        ? h.operators.map((o) => o.namaOperator).toList()
        : (h.namaOperators?.trim().isNotEmpty == true
            ? h.namaOperators!.split(',').map((s) => s.trim()).toList()
            : const <String>[]);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENUGASAN & KEHADIRAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: kVerifikasiInk,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _operatorListField('OPERATOR', namaOperatorList, width: 260),
              _infoField('REGU', h.namaRegu ?? '-'),
              _infoField(
                'HADIR',
                h.hadir != null
                    ? '${h.hadir}${h.jmlhAnggota != null ? ' / ${h.jmlhAnggota}' : ''}'
                    : '-',
              ),
              _infoField('JAM KERJA', h.jamKerja != null ? '${h.jamKerja} jam' : '-'),
              _infoField('HOUR METER', h.hourMeter?.toString() ?? '-'),
              _infoField('BLOWER', h.isBlower ? 'Ya' : 'Tidak'),
              _infoField('OUTPUT', h.outputJenisNama ?? '-', width: 220),
            ],
          ),
        ],
      ),
    );
  }

  Widget _operatorListField(
    String label,
    List<String> names, {
    double width = 140,
  }) {
    return SizedBox(
      width: width,
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
          if (names.isEmpty)
            const Text(
              '-',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kVerifikasiInk,
              ),
            )
          else
            for (final name in names)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kVerifikasiInk,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value, {double width = 140}) {
    return SizedBox(
      width: width,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: kVerifikasiInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(VerifikasiOperatorHeader h, {required bool notReady}) {
    return Padding(
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
                return FilledButton.icon(
                  onPressed:
                      (canVerify && !_isActing && !notReady && !h.verifiedDepartment)
                          ? _handleVerify
                          : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kVerifikasiAccent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    h.verifiedDepartment
                        ? 'Sudah Diverifikasi Kadept'
                        : 'Verifikasi Kadept',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
