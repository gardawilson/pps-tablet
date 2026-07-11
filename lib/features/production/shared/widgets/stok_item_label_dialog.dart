import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/stok_item_data.dart';

/// Dialog rincian label (per pallet/sak) untuk satu item stok,
/// dipanggil saat item pada [StokItemList] di-tap.
/// Generik atas [StokItemData]/[StokLabelData] agar bisa dipakai untuk
/// stok bahan baku proses, stok washing, dsb — sumber datanya ditentukan
/// lewat [fetchLabels].
class StokItemLabelDialog<T extends StokItemData, L extends StokLabelData>
    extends StatefulWidget {
  const StokItemLabelDialog({
    super.key,
    required this.item,
    required this.fetchLabels,
    this.showSakColumn = true,
    this.sakColumnLabel = 'SAK',
  });

  final T item;
  final Future<List<L>> Function(T item) fetchLabels;

  /// Sembunyikan kolom SAK — untuk stok yang cuma dihitung per berat
  /// (mis. crusher).
  final bool showSakColumn;

  /// Label kolom hitungan — default "SAK", mis. "PCS" untuk furniture WIP.
  final String sakColumnLabel;

  @override
  State<StokItemLabelDialog<T, L>> createState() =>
      _StokItemLabelDialogState<T, L>();
}

class _StokItemLabelDialogState<T extends StokItemData, L extends StokLabelData>
    extends State<StokItemLabelDialog<T, L>> {
  static const _sakColWidth = 64.0;
  static const _beratColWidth = 96.0;

  late Future<List<L>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchLabels(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        child: FutureBuilder<List<L>>(
          future: _future,
          builder: (context, snapshot) {
            final labels = (snapshot.data ?? const <StokLabelData>[])
                .where((l) => l.beratSisa > 0)
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 28,
                          color: Color(0xFFB91C1C),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat label\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (labels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 28,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tidak ada label untuk item ini',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildColumnHeader(),
                  Flexible(child: _buildList(labels)),
                  _buildFooter(labels),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 19,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.item.nama,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: const Color(0xFF9CA3AF),
            hoverColor: const Color(0xFFF3F4F6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader() {
    const style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.4,
    );
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
      child: Row(
        children: [
          const Expanded(child: Text('LABEL', style: style)),
          if (widget.showSakColumn) ...[
            SizedBox(
              width: _sakColWidth,
              child: Text(
                widget.sakColumnLabel,
                style: style,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
          ],
          const SizedBox(
            width: _beratColWidth,
            child: Text('BERAT', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLabel(BuildContext context, String label) async {
    await Clipboard.setData(ClipboardData(text: label));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Label "$label" disalin'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildList(List<StokLabelData> labels) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: labels.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final label = labels[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _copyLabel(context, label.label),
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                      if (label.dateCreate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                            'id_ID',
                          ).format(label.dateCreate!.toLocal()),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (widget.showSakColumn) ...[
                SizedBox(
                  width: _sakColWidth,
                  child: Text(
                    '${label.sakSisa}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: _beratColWidth,
                child: Text(
                  '${label.beratSisa.toStringAsFixed(2)} kg',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(List<StokLabelData> labels) {
    final totalSak = labels.fold<int>(0, (sum, l) => sum + l.sakSisa);
    final totalBerat = labels.fold<double>(0, (sum, l) => sum + l.beratSisa);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          if (widget.showSakColumn) ...[
            SizedBox(
              width: _sakColWidth,
              child: Text(
                '$totalSak',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: _beratColWidth,
            child: Text(
              '${totalBerat.toStringAsFixed(2)} kg',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
