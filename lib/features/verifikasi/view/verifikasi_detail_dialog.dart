// lib/features/verifikasi/view/verifikasi_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/error_status_dialog.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_theme.dart';

/// Tampilkan dialog cross-check input vs output untuk satu NoProduksi.
/// [vm] harus di-pass eksplisit karena dialog di-inject ke Overlay Navigator
/// (bukan child dari widget tree pemanggil), jadi tidak bisa mengandalkan
/// context.read/watch langsung tanpa provider baru.
Future<void> showVerifikasiDetailDialog(
  BuildContext context, {
  required VerifikasiViewModel vm,
  required VerifikasiItem item,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider<VerifikasiViewModel>.value(
      value: vm,
      child: VerifikasiDetailDialog(item: item),
    ),
  );
}

/// Dialog cross-check input vs output — gaya enterprise dense, konsisten
/// dengan tabel rekonsiliasi di modul Verifikasi.
class VerifikasiDetailDialog extends StatefulWidget {
  final VerifikasiItem item;

  const VerifikasiDetailDialog({super.key, required this.item});

  @override
  State<VerifikasiDetailDialog> createState() => _VerifikasiDetailDialogState();
}

class _VerifikasiDetailDialogState extends State<VerifikasiDetailDialog> {
  late Future<ProductionCrossCheckSummary> _future;

  @override
  void initState() {
    super.initState();
    final vm = context.read<VerifikasiViewModel>();
    _future = vm.fetchCrossCheck(widget.item);
  }

  Future<void> _handleVerify() async {
    final noteCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verifikasi Produksi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi bahwa input & output untuk ${widget.item.noProduksi} sudah dicek dan sesuai.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
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

    if (confirmed != true || !mounted) return;

    final vm = context.read<VerifikasiViewModel>();
    final ok = await vm.verify(widget.item, note: noteCtl.text.trim());
    if (!mounted) return;

    if (ok) {
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
                    child: _buildReconciliationTable(snapshot.data!),
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
                        return FilledButton.icon(
                          onPressed: canVerify ? _handleVerify : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: kVerifikasiAccent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Verifikasi Produksi Ini'),
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
    final hasJam = (item.hourStart ?? '').isNotEmpty || (item.hourEnd ?? '').isNotEmpty;
    final jam = hasJam ? '${item.hourStart ?? '-'} - ${item.hourEnd ?? '-'}' : '-';

    return Container(
      color: kVerifikasiSurface,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
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

  /// Dua seksi bersisian (Input kiri, Output kanan), masing-masing
  /// bertingkat Kategori → Jenis → Label, lalu ringkasan selisih/rendemen
  /// di bawah sebagai satu baris penuh.
  Widget _buildReconciliationTable(ProductionCrossCheckSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildSection(
                  title: 'INPUT',
                  groups: summary.inputGroups,
                  emptyMessage: 'Tidak ada data input',
                  totalLabel: 'TOTAL INPUT',
                  totalBerat: summary.totalInputBerat,
                ),
              ),
              const VerticalDivider(width: 1, color: kVerifikasiBorder),
              Expanded(
                child: _buildSection(
                  title: 'OUTPUT',
                  groups: summary.outputGroups,
                  emptyMessage: 'Tidak ada data output',
                  totalLabel: 'TOTAL OUTPUT',
                  totalBerat: summary.totalOutputBerat,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: kVerifikasiBorder),
        _buildVarianceSummary(summary),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<ProductionCategoryGroup> groups,
    required String emptyMessage,
    required String totalLabel,
    required double totalBerat,
  }) {
    final hasData = groups.any((g) => g.jenisGroups.isNotEmpty);

    // Kalau cuma ada satu kategori dan namanya generik (sama dengan judul
    // seksi, mis. "Output"), header kategori jadi duplikat judul seksi —
    // langsung tampilkan jenisGroups-nya tanpa header kategori.
    final flattenSingleCategory = groups.length == 1 &&
        groups.first.categoryLabel.trim().toUpperCase() == title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitleRow(title),
        if (!hasData)
          _emptyRow(emptyMessage)
        else if (flattenSingleCategory)
          for (final j in groups.first.jenisGroups)
            _jenisBlock(j, indent: 14)
        else
          for (final g in groups)
            if (g.jenisGroups.isNotEmpty) _categoryBlock(g),
        _subtotalRow(totalLabel, totalBerat),
      ],
    );
  }

  Widget _sectionTitleRow(String title) {
    return Container(
      color: kVerifikasiSurface,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: kVerifikasiAccent,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Level 1: kategori (mis. "Bahan Baku", "Washing", "Output") ─────────────
  Widget _categoryBlock(ProductionCategoryGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFFAFAFA),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  g.categoryLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kVerifikasiInk,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                '${g.totalSak} label',
                style: const TextStyle(fontSize: 10.5, color: kVerifikasiMuted),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  '${g.totalBerat.toStringAsFixed(2)} kg',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: kVerifikasiInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final j in g.jenisGroups) _jenisBlock(j),
      ],
    );
  }

  // ── Level 2: jenis material (namaJenis) ────────────────────────────────────
  Widget _jenisBlock(ProductionJenisGroup j, {double indent = 24}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(indent, 7, 14, 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  j.namaJenis,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kVerifikasiInk,
                  ),
                ),
              ),
              Text(
                '${j.totalSak} label',
                style: const TextStyle(fontSize: 10.5, color: kVerifikasiMuted),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  '${j.totalBerat.toStringAsFixed(2)} kg',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kVerifikasiInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final l in j.labels) _labelRow(l, indent: indent + 10),
      ],
    );
  }

  // ── Level 3: nomor label individual ────────────────────────────────────────
  Widget _labelRow(ProductionLabelDetail l, {double indent = 34}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      padding: EdgeInsets.fromLTRB(indent, 5, 14, 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.labelNo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: kVerifikasiMuted),
            ),
          ),
          if (l.sakCount > 1) ...[
            Text(
              '${l.sakCount} sak',
              style: const TextStyle(fontSize: 10.5, color: kVerifikasiMuted),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 80,
            child: Text(
              '${l.berat.toStringAsFixed(2)} kg',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, color: kVerifikasiInk),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtotalRow(String label, double totalBerat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: kVerifikasiSurface,
        border: Border(top: BorderSide(color: kVerifikasiBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: kVerifikasiInk,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              totalBerat.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kVerifikasiInk),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: kVerifikasiMuted),
      ),
    );
  }

  /// Ringkasan selisih berat output vs input + rendemen, membentang penuh
  /// di bawah dua seksi input/output.
  Widget _buildVarianceSummary(ProductionCrossCheckSummary summary) {
    final rendemen = summary.rendemenPct;
    final isLowYield = rendemen != null && rendemen < 80;
    final varianceColor = rendemen == null
        ? kVerifikasiMuted
        : (isLowYield ? kVerifikasiWarning : kVerifikasiSuccess);
    final varianceBg = rendemen == null
        ? kVerifikasiSurface
        : (isLowYield ? kVerifikasiWarningBg : kVerifikasiSuccessBg);

    return Container(
      color: varianceBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'SELISIH OUTPUT vs INPUT (SUSUT PROSES)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: varianceColor,
              ),
            ),
          ),
          Text(
            rendemen != null ? 'Rendemen ${rendemen.toStringAsFixed(1)}%' : '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: varianceColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${summary.selisihBerat.toStringAsFixed(2)} kg',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: varianceColor,
            ),
          ),
        ],
      ),
    );
  }
}
