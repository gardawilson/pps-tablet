// lib/features/furniture_wip/widgets/furniture_wip_header_table.dart

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../common/widgets/horizontal_paged_table.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../model/furniture_wip_header_model.dart';
import '../../../../core/utils/date_formatter.dart';

class FurnitureWipHeaderTable extends StatelessWidget {
  /// Paging controller (dipegang di ViewModel / Screen)
  final PagingController<int, FurnitureWipHeader> pagingController;

  /// NoFurnitureWIP yang sedang selected (untuk highlight row)
  final String? selectedNoFurnitureWip;

  /// Tap biasa pada row
  final ValueChanged<FurnitureWipHeader>? onItemTap;

  /// Long-press (dengan posisi global) – untuk context menu / popover row
  final void Function(FurnitureWipHeader header, Offset globalPosition)?
  onItemLongPress;

  /// Callback saat row partial diklik (tanpa posisi tap)
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
    return HorizontalPagedTable<FurnitureWipHeader>(
      pagingController: pagingController,
      widthMode: TableWidthMode.content, // atau fill/clamp sesuai selera
      rowHeight: 52,
      headerColor: const Color(0xFF1565C0),
      horizontalPadding: 16,
      selectedPredicate: (row) => row.noFurnitureWip == selectedNoFurnitureWip,
      onRowTap: (row) {
        // callback utama ke Screen
        onItemTap?.call(row);

        // kalau partial dan punya handler khusus
        if (row.isPartialBool && onPartialTap != null) {
          onPartialTap!(row);
        }
      },
      onRowLongPress: (row, pos) {
        onItemLongPress?.call(row, pos);
      },
      columns: _buildColumns(),
    );
  }

  List<TableColumnSpec<FurnitureWipHeader>> _buildColumns() {
    return [
      // =========================
      // NO. FURNITURE WIP
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'NO. LABEL',
        width: 170,
        headerAlign: TextAlign.left,
        cellAlign: TextAlign.left,
        cellBuilder: (context, item) {
          final isPartial = item.isPartialBool;
          return Row(
            children: [
              Expanded(
                child: Text(
                  item.noFurnitureWip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPartial) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Klik untuk lihat detail partial',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ],
          );
        },
      ),

      // =========================
      // TANGGAL
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'TANGGAL',
        width: 130,
        headerAlign: TextAlign.left,
        cellAlign: TextAlign.left,
        cellBuilder: (context, item) {
          return Text(
            formatDateToShortId(item.dateCreate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),

      // =========================
      // JENIS (NamaFurnitureWIP)
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'JENIS',
        width: 350,
        headerAlign: TextAlign.left,
        cellAlign: TextAlign.left,
        cellBuilder: (context, item) {
          return Text(
            item.namaFurnitureWip ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),

      // =========================
      // OUTPUT (Kode + Nama Mesin/Pembeli/Bongkar)
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'PROSES',
        width: 170,
        headerAlign: TextAlign.left,
        cellAlign: TextAlign.left,
        cellBuilder: (context, item) {
          final code = item.outputCode ?? '-';
          final nama = (item.outputNamaMesin ?? '').trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (nama.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          );
        },
      ),

      // =========================
      // PCS (right-align)
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'PCS',
        width: 80,
        headerAlign: TextAlign.right,
        cellAlign: TextAlign.right,
        cellBuilder: (context, item) {
          final txt = _formatPcs(item.pcs);
          return Text(
            txt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight:
              item.isPartialBool ? FontWeight.bold : FontWeight.w500,
              color: item.isPartialBool ? Colors.red : null,
            ),
          );
        },
      ),

      // =========================
      // BERAT (right-align)
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'BERAT',
        width: 100,
        headerAlign: TextAlign.right,
        cellAlign: TextAlign.right,
        cellBuilder: (context, item) {
          final txt = _formatBerat(item.berat);
          return Text(
            txt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),

      // =========================
      // LOKASI (center-align biar rapi)
      // =========================
      TableColumnSpec<FurnitureWipHeader>(
        title: 'LOKASI',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlign: TextAlign.center,
        cellBuilder: (context, item) {
          final txt = _formatBlokLokasi(item.blok, item.idLokasi);
          return Text(
            txt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    ];
  }

  // ==== Helpers ====

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
    final hasLokasi =
        idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    return '${blok ?? ''}${idLokasi ?? ''}';
  }
}
