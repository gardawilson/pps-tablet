import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProduksiRowData {
  final DateTime? tglProduksi;
  final String? hourStart;
  final String? hourEnd;
  final int shift;
  final bool isLocked;
  final String namaMesin;
  final String? namaRegu;
  final String? outputJenisNama;

  // inject-specific fields (cetakan/warna/material)
  final String? namaCetakan;
  final String? namaWarna;
  final String? namaFurnitureMaterial;

  const ProduksiRowData({
    required this.tglProduksi,
    required this.hourStart,
    required this.hourEnd,
    required this.shift,
    required this.isLocked,
    required this.namaMesin,
    this.namaRegu,
    this.outputJenisNama,
    this.namaCetakan,
    this.namaWarna,
    this.namaFurnitureMaterial,
  });
}

class ProductionProduksiList<T> extends StatelessWidget {
  const ProductionProduksiList({
    super.key,
    required this.items,
    required this.dataOf,
    required this.isLoading,
    required this.isFetchingMore,
    required this.scrollController,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
    this.showMesin = true,
  });

  final List<T> items;
  final ProduksiRowData Function(T) dataOf;
  final bool isLoading;
  final bool isFetchingMore;
  final ScrollController scrollController;
  final Future<void> Function(T) onTap;
  final Future<void> Function(T) onEdit;
  final Future<void> Function(T) onDelete;
  final Future<void> Function(T) onInput;
  final bool showMesin;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 6),
            Text(
              'Belum ada data produksi',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      itemCount: items.length + (isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = items[index];
        final data = dataOf(item);
        return _ProduksiRow(
          data: data,
          showMesin: showMesin,
          onTap: () => onTap(item),
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
          onInput: () => onInput(item),
        );
      },
    );
  }
}

const _kBlue = Color(0xFF1D4ED8);
const _kLocked = Color(0xFFF97316);
const _kGreen = Color(0xFF059669);
const _kRed = Color(0xFFDC2626);

class _ProduksiRow extends StatelessWidget {
  const _ProduksiRow({
    required this.data,
    required this.showMesin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onInput,
  });

  final ProduksiRowData data;
  final bool showMesin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onInput;

  String _fmtDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date.toLocal());
  }

  String _fmtTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    final hasCetakanInfo = (data.namaCetakan ?? '').trim().isNotEmpty ||
        (data.namaWarna ?? '').trim().isNotEmpty ||
        (data.namaFurnitureMaterial ?? '').trim().isNotEmpty;

    final metaItems = <_MetaItem>[
      if (showMesin)
        _MetaItem(
          label: 'Mesin',
          value: data.namaMesin.trim().isNotEmpty
              ? data.namaMesin.trim()
              : '-',
        ),
      if (hasCetakanInfo) ...[
        if ((data.namaCetakan ?? '').trim().isNotEmpty)
          _MetaItem(
            label: 'Cetakan',
            value: data.namaCetakan!.trim(),
          ),
        if ((data.namaWarna ?? '').trim().isNotEmpty)
          _MetaItem(
            label: 'Warna',
            value: data.namaWarna!.trim(),
          ),
        _MetaItem(
          label: 'Material',
          value: (data.namaFurnitureMaterial ?? '').trim().isNotEmpty
              ? data.namaFurnitureMaterial!.trim()
              : '-',
        ),
      ] else ...[
        _MetaItem(
          label: 'Regu',
          value: (data.namaRegu ?? '').trim().isNotEmpty
              ? data.namaRegu!.trim()
              : '-',
        ),
        _MetaItem(
          label: 'Output',
          value: (data.outputJenisNama ?? '').trim().isNotEmpty
              ? data.outputJenisNama!.trim()
              : '-',
        ),
      ],
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDate(data.tglProduksi),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_fmtTime(data.hourStart)} - ${_fmtTime(data.hourEnd)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TitleBadge(text: 'Shift ${data.shift}'),
                          if (data.isLocked)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: _StatusChip(
                                label: 'Locked',
                                foreground: _kLocked,
                                background: Color(0xFFFFF7ED),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _MetaSection(items: metaItems),
                    ],
                  ),
                ),
                _ActionMenu(
                  onInput: onInput,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBadge extends StatelessWidget {
  const _TitleBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

class _MetaItem {
  const _MetaItem({required this.label, required this.value});
  final String label;
  final String value;
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.items});
  final List<_MetaItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFFE5E7EB),
                ),
              Expanded(child: _MetaColumn(item: items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({required this.item});
  final _MetaItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foreground,
    required this.background,
  });
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.onInput,
    required this.onEdit,
    required this.onDelete,
  });
  final VoidCallback onInput;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
        tooltip: 'Aksi',
        onSelected: (value) {
          if (value == 'input') onInput();
          if (value == 'edit') onEdit();
          if (value == 'hapus') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'input',
            height: 38,
            child: Row(
              children: [
                Icon(Icons.edit_note_outlined, size: 15, color: _kGreen),
                SizedBox(width: 8),
                Text('Input', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            height: 38,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 15, color: _kBlue),
                SizedBox(width: 8),
                Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'hapus',
            height: 38,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 15, color: _kRed),
                SizedBox(width: 8),
                Text('Hapus', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
