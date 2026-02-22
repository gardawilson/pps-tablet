import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/furniture_wip_header_model.dart';

class FurnitureWipHeaderTable extends StatelessWidget {
  final PagingController<int, FurnitureWipHeader> pagingController;
  final String? selectedNoFurnitureWip;
  final ValueChanged<FurnitureWipHeader>? onItemTap;
  final void Function(FurnitureWipHeader header, Offset globalPosition)?
  onItemLongPress;
  final ValueChanged<FurnitureWipHeader>? onPartialTap;

  const FurnitureWipHeaderTable({
    super.key,
    required this.pagingController,
    this.selectedNoFurnitureWip,
    this.onItemTap,
    this.onItemLongPress,
    this.onPartialTap,
  });

  @override
  Widget build(BuildContext context) {
    return AtlasPagedDataTable<FurnitureWipHeader>(
      pagingController: pagingController,
      columns: _buildColumns(),
      selectedPredicate: (row) => row.noFurnitureWip == selectedNoFurnitureWip,
      onRowTap: (row) {
        onItemTap?.call(row);
        if (row.isPartialBool && onPartialTap != null) {
          onPartialTap!(row);
        }
      },
      onRowLongPress: (row, pos) => onItemLongPress?.call(row, pos),
    );
  }

  List<AtlasTableColumn<FurnitureWipHeader>> _buildColumns() {
    return [
      AtlasTableColumn<FurnitureWipHeader>(
        title: 'NO. LABEL',
        width: 170,
        cellBuilder: (context, item, rowState) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  item.noFurnitureWip,
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
      AtlasTableColumn<FurnitureWipHeader>(
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
      AtlasTableColumn<FurnitureWipHeader>(
        title: 'JENIS',
        width: 350,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaFurnitureWip ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<FurnitureWipHeader>(
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
      AtlasTableColumn<FurnitureWipHeader>(
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
      AtlasTableColumn<FurnitureWipHeader>(
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
      AtlasTableColumn<FurnitureWipHeader>(
        title: 'LOKASI',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBlokLokasi(item.blok, item.idLokasi),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
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
