import 'package:flutter/material.dart';

import '../model/broker_production_model.dart';

/// Panel list riwayat produksi broker (panel kanan).
/// Menangani loading state, infinite scroll, dan aksi per-baris.
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
          showRegu: filterIdMesin != null,
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
class _BrokerProduksiRow extends StatelessWidget {
  const _BrokerProduksiRow({
    required this.row,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.showRegu = false,
  });

  final BrokerProduction row;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onInput;
  final bool showRegu;

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final jenis = (row.outputJenisNama ?? '').trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Tanggal + shift + jam
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(row.tglProduksi),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shift ${row.shift}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  Text(
                    '${row.hourStart ?? '--:--'} – ${row.hourEnd ?? '--:--'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Mesin / Regu name
              Expanded(
                flex: 2,
                child: Text(
                  showRegu
                      ? (row.namaRegu?.trim().isNotEmpty == true
                          ? row.namaRegu!.trim()
                          : '-')
                      : row.namaMesin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Jenis output
              Expanded(
                flex: 3,
                child: Text(
                  jenis.isEmpty ? '-' : jenis,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: jenis.isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151),
                    fontStyle:
                        jenis.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                tooltip: 'Aksi',
                onSelected: (value) {
                  if (value == 'input') onInput();
                  if (value == 'edit') onEdit();
                  if (value == 'hapus') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'input',
                    child: Row(
                      children: [
                        Icon(
                          Icons.input_outlined,
                          size: 16,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 8),
                        Text('Input', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF0D47A1),
                        ),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
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
      ),
    );
  }
}
