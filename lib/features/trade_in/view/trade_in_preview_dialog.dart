import 'package:flutter/material.dart';

import '../model/trade_in_reject_detail.dart';
import '../model/trade_in_transaction.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);

/// Dialog preview read-only 1 penerimaan trade-in — menampilkan seluruh
/// field yang ada pada response list (tidak ada mode edit) beserta tombol
/// cetak label reject terkait, kalau ada.
class TradeInPreviewDialog extends StatefulWidget {
  final TradeInTransaction item;
  final Future<void> Function(TradeInRejectDetail reject) onPrintReject;

  /// Konfirmasi + eksekusi hapus di caller — return `true` kalau berhasil
  /// dihapus, supaya dialog ini tahu kapan harus menutup diri.
  final Future<bool> Function() onDelete;

  const TradeInPreviewDialog({
    super.key,
    required this.item,
    required this.onPrintReject,
    required this.onDelete,
  });

  @override
  State<TradeInPreviewDialog> createState() => _TradeInPreviewDialogState();
}

class _TradeInPreviewDialogState extends State<TradeInPreviewDialog> {
  bool _printing = false;
  bool _deleting = false;

  Future<void> _print() async {
    final reject = widget.item.reject;
    if (reject == null || _printing) return;
    setState(() => _printing = true);
    await widget.onPrintReject(reject);
    if (!mounted) return;
    setState(() => _printing = false);
  }

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    final deleted = await widget.onDelete();
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reject = item.reject;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(item),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('No. Penerimaan', item.noPenerimaan),
                    _row('Tanggal', item.tanggal),
                    _row(
                      'Supplier',
                      item.supplier.isEmpty ? '-' : item.supplier,
                    ),
                    _row(
                      'Sales Person',
                      item.salesPersonName.isEmpty
                          ? (item.salesPersonCode.isEmpty
                                ? '-'
                                : item.salesPersonCode)
                          : item.salesPersonName,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: _kBorder),
                    const SizedBox(height: 12),
                    const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (reject == null)
                      Text(
                        'Belum ada label reject',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      )
                    else ...[
                      _row('No. Reject', reject.noReject),
                      _row('Jenis Reject', reject.namaReject),
                      _row('Berat', '${_formatWeight(reject.berat)} kg'),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _deleting || _printing ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _deleting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade600,
                            ),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: reject == null || _printing || _deleting
                          ? null
                          : _print,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _printing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print_rounded, size: 18),
                      label: Text(
                        reject == null
                            ? 'Tidak Ada Label Reject'
                            : 'Cetak Label Reject',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildHeader(TradeInTransaction item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: _kPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Penerimaan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                Text(
                  item.noPenerimaan,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D23),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
