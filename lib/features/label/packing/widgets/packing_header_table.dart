import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/packing_header_model.dart';

class PackingHeaderTable extends StatelessWidget {
  final PagingController<int, PackingHeader> pagingController;
  final String? selectedNoBJ;
  final ValueChanged<PackingHeader>? onItemTap;
  final void Function(PackingHeader header, Offset globalPosition)?
  onItemLongPress;
  final ValueChanged<PackingHeader>? onPartialTap;

  const PackingHeaderTable({
    super.key,
    required this.pagingController,
    this.selectedNoBJ,
    this.onItemTap,
    this.onItemLongPress,
    this.onPartialTap,
  });

  @override
  Widget build(BuildContext context) {
    return AtlasPagedDataTable<PackingHeader>(
      pagingController: pagingController,
      columns: _buildColumns(),
      selectedPredicate: (row) => row.noBJ == selectedNoBJ,
      onRowTap: (row) {
        onItemTap?.call(row);
        if (row.isPartialBool && onPartialTap != null) {
          onPartialTap!(row);
        }
      },
      onRowLongPress: (row, pos) => onItemLongPress?.call(row, pos),
    );
  }

  List<AtlasTableColumn<PackingHeader>> _buildColumns() {
    return [
      AtlasTableColumn<PackingHeader>(
        title: 'NO. LABEL',
        width: 150,
        cellBuilder: (context, item, rowState) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  item.noBJ,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: rowState.isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: rowState.isSelected
                        ? const Color(0xFF0C66E4)
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'TANGGAL',
        width: 130,
        cellBuilder: (context, item, rowState) {
          return Text(
            formatDateToShortId(item.dateCreate),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'JENIS',
        width: 300,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaBJ ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'PROSES',
        width: 170,
        cellBuilder: (context, item, rowState) {
          final code = item.outputCode ?? '-';
          final nama = (item.outputNamaMesin ?? '').trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rowState.isSelected
                      ? const Color(0xFF0C66E4)
                      : Colors.black87,
                ),
                softWrap: true,
              ),
              if (nama.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  nama,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  softWrap: true,
                ),
              ],
            ],
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'PCS',
        width: 80,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatPcs(item.pcs),
            style: TextStyle(
              fontSize: 14,
              fontWeight: item.isPartialBool
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: item.isPartialBool ? Colors.red : rowState.textColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'BERAT',
        width: 100,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBerat(item.berat),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'LOKASI',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBlokLokasi(item.blok, item.idLokasi),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingHeader>(
        title: 'PRINT',
        width: 72,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          final count = item.hasBeenPrinted;
          if (count == 0) {
            return Text(
              '—',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0C66E4).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0C66E4).withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.print_rounded,
                  size: 12,
                  color: Color(0xFF0C66E4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${count}x',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C66E4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  String _formatPcs(double? v) {
    if (v == null) return '-';
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  String _formatBerat(double? v) {
    if (v == null) return '-';
    return v.toStringAsFixed(2);
  }

  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    return '${blok ?? ''}${idLokasi ?? ''}';
  }
}
