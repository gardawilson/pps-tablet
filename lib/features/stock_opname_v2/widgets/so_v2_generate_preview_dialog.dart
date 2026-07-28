// lib/features/stock_opname_v2/widgets/so_v2_generate_preview_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/so_v2_generate_preview.dart';
import '../utils/so_v2_number_format.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kInk = Color(0xFF1A1D23);
const _kMuted = Color(0xFF6B7280);

/// Dialog preview sebelum generate No. Stock Opname — tampilkan breakdown
/// per jenis biar supervisor tahu persis apa yang bakal ke-generate sebelum
/// benar-benar bikin SO baru.
///
/// Return `true` kalau user menekan "Generate", `false`/`null` kalau batal.
Future<bool?> showSoV2GeneratePreviewDialog(
  BuildContext context, {
  required SoV2GeneratePreview preview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => SoV2GeneratePreviewDialog(preview: preview),
  );
}

class SoV2GeneratePreviewDialog extends StatelessWidget {
  final SoV2GeneratePreview preview;

  const SoV2GeneratePreviewDialog({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final weightUnit = preview.categoryCode == 'furniturewip' ? 'pcs' : 'kg';
    final qtyLabel = weightUnit == 'pcs' ? 'PCS' : 'BERAT';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
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
                    _buildTotalRow(qtyLabel),
                    if (preview.perJenis.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionTitle('PER JENIS'),
                      const SizedBox(height: 6),
                      _buildBreakdownTable(),
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
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                      label: const Text('Generate'),
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
    final dateLabel = preview.date != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(preview.date!.toLocal())
        : null;

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
                  'Generate Stock Opname',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview.hasDateFilter && dateLabel != null
                      ? '${preview.categoryName} · per $dateLabel'
                      : preview.categoryName,
                  style: const TextStyle(fontSize: 11.5, color: _kMuted),
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

  Widget _buildTotalRow(String qtyLabel) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(label: 'TOTAL LABEL', value: '${preview.labelCount}'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: qtyLabel,
            value: soV2FormatQty(preview.totalWeight),
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

  Widget _buildBreakdownTable() {
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
                Expanded(flex: 3, child: _headCell('Jenis')),
                Expanded(flex: 2, child: _headCell('Label', align: TextAlign.right)),
                Expanded(flex: 2, child: _headCell('Qty', align: TextAlign.right)),
              ],
            ),
          ),
          for (int i = 0; i < preview.perJenis.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
            _buildRow(preview.perJenis[i]),
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

  Widget _buildRow(SoV2GeneratePreviewJenis jenis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              jenis.typeName,
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
              '${jenis.labelCount}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              soV2FormatQty(jenis.totalWeight),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.5, color: _kInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _kInk,
            ),
          ),
        ],
      ),
    );
  }
}
