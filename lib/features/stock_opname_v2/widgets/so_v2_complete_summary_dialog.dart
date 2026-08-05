// lib/features/stock_opname_v2/widgets/so_v2_complete_summary_dialog.dart
import 'package:flutter/material.dart';

import '../model/so_v2_complete_summary.dart';
import '../utils/so_v2_number_format.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kInk = Color(0xFF1A1D23);
const _kMuted = Color(0xFF6B7280);
const _kWarning = Color(0xFFB45309);
const _kWarningBg = Color(0xFFFFF7ED);
const _kSuccess = Color(0xFF0A7349);

/// Dialog ringkasan sebelum "Tandai Selesai" stock opname — tampilkan
/// progres scan (total, per jenis, per blok) dan peringatan penugasan
/// lokasi yang bakal ke-revoke otomatis, supaya supervisor sadar dampaknya
/// sebelum benar-benar menandai selesai.
///
/// Return `true` kalau user menekan "Tandai Selesai", `false`/`null` kalau
/// batal.
Future<bool?> showSoV2CompleteSummaryDialog(
  BuildContext context, {
  required SoV2CompleteSummary summary,
  required String weightUnit,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => SoV2CompleteSummaryDialog(
      summary: summary,
      weightUnit: weightUnit,
    ),
  );
}

class SoV2CompleteSummaryDialog extends StatelessWidget {
  final SoV2CompleteSummary summary;
  final String weightUnit;

  const SoV2CompleteSummaryDialog({
    super.key,
    required this.summary,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnscanned = summary.total.unscannedCount > 0;
    final qtyLabel = weightUnit == 'pcs' ? 'PCS' : 'BERAT';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasUnscanned) ...[
                      _buildUnscannedWarning(),
                      const SizedBox(height: 14),
                    ],
                    _buildTotalRow(qtyLabel),
                    if (summary.perJenis.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('PER JENIS'),
                      const SizedBox(height: 6),
                      _buildBreakdownTable(
                        headLabel: 'Jenis',
                        rows: [
                          for (final j in summary.perJenis)
                            _BreakdownRow(
                              label: j.typeName,
                              labelCount: j.labelCount,
                              scannedCount: j.scannedCount,
                              unscannedCount: j.unscannedCount,
                              totalWeight: j.totalWeight,
                            ),
                        ],
                      ),
                    ],
                    if (summary.perBlok.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('PER BLOK'),
                      const SizedBox(height: 6),
                      _buildBreakdownTable(
                        headLabel: 'Blok',
                        rows: [
                          for (final b in summary.perBlok)
                            _BreakdownRow(
                              label: 'Blok ${b.blok} (${b.locationCount} lokasi)',
                              labelCount: b.labelCount,
                              scannedCount: b.scannedCount,
                              unscannedCount: b.unscannedCount,
                              totalWeight: b.totalWeight,
                            ),
                        ],
                      ),
                    ],
                    if (summary.assignedUsersCount > 0) ...[
                      const SizedBox(height: 14),
                      _buildAssignedUsersWarning(),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kMuted,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kSuccess,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Tandai Selesai'),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FB),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.stockOpnameNo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary.categoryName,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, size: 18, color: _kMuted),
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  Widget _buildUnscannedWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kWarningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kWarning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: _kWarning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Masih ada ${summary.total.unscannedCount} label yang belum di-scan. Setelah selesai, label ini tidak dapat di-scan lagi.',
              style: const TextStyle(
                fontSize: 12,
                color: _kWarning,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedUsersWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_off_outlined, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${summary.assignedUsersCount} penugasan user ke lokasi akan otomatis dihapus setelah SO ditandai selesai.',
              style: const TextStyle(
                fontSize: 12,
                color: _kPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String qtyLabel) {
    final t = summary.total;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'TOTAL LABEL',
            value: '${t.labelCount}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'SUDAH SCAN',
            value: '${t.scannedCount}',
            valueColor: _kSuccess,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: 'BELUM SCAN',
            value: '${t.unscannedCount}',
            valueColor: t.unscannedCount > 0 ? _kWarning : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: qtyLabel,
            value: soV2FormatQty(t.totalWeight),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: _kMuted,
      ),
    );
  }

  Widget _buildBreakdownTable({
    required String headLabel,
    required List<_BreakdownRow> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: _headCell(headLabel)),
                Expanded(flex: 2, child: _headCell('Scan', align: TextAlign.right)),
                Expanded(flex: 2, child: _headCell('Qty', align: TextAlign.right)),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
            _buildBreakdownRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _headCell(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: _kMuted,
      ),
    );
  }

  Widget _buildBreakdownRow(_BreakdownRow row) {
    final hasWarning = row.unscannedCount > 0;
    return Container(
      color: hasWarning ? _kWarningBg.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.scannedCount}/${row.labelCount}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasWarning ? _kWarning : _kSuccess,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              soV2FormatQty(row.totalWeight),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, color: _kInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow {
  final String label;
  final int labelCount;
  final int scannedCount;
  final int unscannedCount;
  final double totalWeight;

  const _BreakdownRow({
    required this.label,
    required this.labelCount,
    required this.scannedCount,
    required this.unscannedCount,
    required this.totalWeight,
  });
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _kMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor ?? _kInk,
            ),
          ),
        ],
      ),
    );
  }
}
