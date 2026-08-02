// lib/features/verifikasi/view/widgets/reconciliation_section.dart

import 'package:flutter/material.dart';

import '../../model/verifikasi_models.dart';
import '../verifikasi_theme.dart';

/// Dua seksi bersisian (Input kiri, Output kanan), masing-masing bertingkat
/// Kategori → Jenis → Label, lalu ringkasan selisih/rendemen di bawah
/// sebagai satu baris penuh. Dipakai bersama oleh dialog "Verifikasi Kepala
/// Stok" & "Verifikasi Operator" supaya tampilan cross-check konsisten.
class ReconciliationSection extends StatelessWidget {
  final ProductionCrossCheckSummary summary;

  /// Kalau false, baris label individual (level 3) disembunyikan — hanya
  /// tampilkan kategori → jenis + total berat/qty. Dipakai dialog
  /// "Verifikasi Operator" yang tidak butuh rincian per label.
  final bool showLabels;

  const ReconciliationSection({
    super.key,
    required this.summary,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Section(
                  title: 'INPUT',
                  groups: summary.inputGroups,
                  emptyMessage: 'Tidak ada data input',
                  totalLabel: 'TOTAL INPUT',
                  totalBerat: summary.totalInputBerat,
                  showLabels: showLabels,
                ),
              ),
              const VerticalDivider(width: 1, color: kVerifikasiBorder),
              Expanded(
                child: _Section(
                  title: 'OUTPUT',
                  groups: summary.outputGroups,
                  emptyMessage: 'Tidak ada data output',
                  totalLabel: 'TOTAL OUTPUT',
                  totalBerat: summary.totalOutputBerat,
                  showLabels: showLabels,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: kVerifikasiBorder),
        _VarianceSummary(summary: summary),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ProductionCategoryGroup> groups;
  final String emptyMessage;
  final String totalLabel;
  final double totalBerat;
  final bool showLabels;

  const _Section({
    required this.title,
    required this.groups,
    required this.emptyMessage,
    required this.totalLabel,
    required this.totalBerat,
    required this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = groups.any((g) => g.jenisGroups.isNotEmpty);

    // Kalau cuma ada satu kategori dan namanya generik (sama dengan judul
    // seksi, mis. "Output"), header kategori jadi duplikat judul seksi —
    // langsung tampilkan jenisGroups-nya tanpa header kategori.
    final flattenSingleCategory =
        groups.length == 1 &&
        groups.first.categoryLabel.trim().toUpperCase() == title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitleRow(title),
        if (!hasData)
          _emptyRow(emptyMessage)
        else if (flattenSingleCategory)
          for (final j in groups.first.jenisGroups) _jenisBlock(j, indent: 14)
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

  // ── Level 1: kategori (mis. "Bahan Baku", "Washing", "Output") ───────────
  Widget _categoryBlock(ProductionCategoryGroup g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFFAFAFA),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
        for (final j in g.jenisGroups) _jenisBlock(j),
      ],
    );
  }

  // ── Level 2: jenis material (namaJenis) ───────────────────────────────────
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
                '${j.totalSak} sak',
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
        if (showLabels)
          for (final l in j.labels) _labelRow(l, indent: indent + 10),
      ],
    );
  }

  // ── Level 3: nomor label individual ───────────────────────────────────────
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kVerifikasiInk,
              ),
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
}

/// Ringkasan selisih berat output vs input + rendemen, membentang penuh
/// di bawah dua seksi input/output.
class _VarianceSummary extends StatelessWidget {
  final ProductionCrossCheckSummary summary;

  const _VarianceSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
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
