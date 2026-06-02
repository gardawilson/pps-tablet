import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/broker_production_model.dart';

class BrokerProduksiList extends StatelessWidget {
  const BrokerProduksiList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isFetchingMore,
    required this.scrollController,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.filterIdMesin,
  });

  final List<BrokerProduction> items;
  final bool isLoading;
  final bool isFetchingMore;
  final ScrollController scrollController;
  final Future<void> Function(BrokerProduction) onTap;
  final Future<void> Function(BrokerProduction) onEdit;
  final Future<void> Function(BrokerProduction) onDelete;
  final Future<void> Function(BrokerProduction) onInput;
  final int? filterIdMesin;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data produksi',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length + (isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final row = items[index];
        return _BrokerProduksiRow(
          row: row,
          filterAll: filterIdMesin == null,
          onTap: () => onTap(row),
          onEdit: () => onEdit(row),
          onDelete: () => onDelete(row),
          onInput: () => onInput(row),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row item
// ─────────────────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFF1D4ED8);
const _kBorder = Color(0xFFE5E7EB);

class _BrokerProduksiRow extends StatelessWidget {
  const _BrokerProduksiRow({
    required this.row,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.filterAll = true,
  });

  final BrokerProduction row;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onInput;
  final bool filterAll;

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(d.toLocal());
  }

  String _fmtTime(String? t) => (t ?? '--:--').length >= 5 ? t!.substring(0, 5) : (t ?? '--:--');

  @override
  Widget build(BuildContext context) {
    final jenis = (row.outputJenisNama ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top: tanggal · shift · jam  |  noProduksi ────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: _kAccent.withValues(alpha: 0.06),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: _kAccent),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(row.tglProduksi),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ShiftBadge(shift: row.shift),
                  const SizedBox(width: 10),
                  Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    '${_fmtTime(row.hourStart)} – ${_fmtTime(row.hourEnd)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    row.noProduksi,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            // ── Bottom: detail + actions ──────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(12, filterAll ? 8 : 5, 4, filterAll ? 8 : 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (filterAll) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.precision_manufacturing_outlined, size: 11, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  row.namaMesin,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ] else if ((row.namaRegu ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.groups_outlined, size: 11, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  row.namaRegu!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (jenis.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              const Icon(Icons.label_outline, size: 11, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  jenis,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF6B7280)),
                    tooltip: 'Aksi',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'hapus') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0D47A1)),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'hapus',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.shift});
  final int shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Shift $shift',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kAccent,
        ),
      ),
    );
  }
}
