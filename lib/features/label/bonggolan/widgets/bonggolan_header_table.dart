import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bonggolan_header_model.dart';
import '../view_model/bonggolan_view_model.dart';

class BonggolanHeaderTable extends StatelessWidget {
  static const _colNoBonggolanWidth = 150.0;
  static const _colTanggalWidth = 108.0;
  static const _colBeratWidth = 92.0;
  static const _colLokasiWidth = 96.0;

  final ScrollController scrollController;
  final ValueChanged<BonggolanHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(BonggolanHeader header, Offset globalPosition)
  onItemLongPress;

  const BonggolanHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BonggolanViewModel>(
      builder: (context, vm, _) {
        return AtlasDataTable<BonggolanHeader>(
          columns: _buildColumns(),
          items: vm.items,
          scrollController: scrollController,
          isLoading: vm.isLoading,
          isFetchingMore: vm.isFetchingMore,
          errorMessage: vm.errorMessage,
          errorBuilder: _buildErrorState,
          selectedPredicate: (item) =>
              vm.selectedNoBonggolan == item.noBonggolan,
          onRowTap: onItemTap,
          onRowLongPress: onItemLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<BonggolanHeader>> _buildColumns() {
    return [
      AtlasTableColumn<BonggolanHeader>(
        title: 'NO. BONGGOLAN',
        width: _colNoBonggolanWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noBonggolan,
            style: TextStyle(
              fontSize: 14,
              fontWeight: rowState.isSelected
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: rowState.isSelected
                  ? const Color(0xFF0C66E4)
                  : Colors.black87,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BonggolanHeader>(
        title: 'TANGGAL',
        width: _colTanggalWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            formatDateToShortId(item.dateCreate),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BonggolanHeader>(
        title: 'JENIS',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaBonggolan ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BonggolanHeader>(
        title: 'BERAT',
        width: _colBeratWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.berat.toString(),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BonggolanHeader>(
        title: 'PROSES',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          final code = (item.refNoProduksi ?? '').trim().isNotEmpty
              ? item.refNoProduksi!.trim()
              : ((item.noBongkarSusun ?? '').trim().isNotEmpty
                    ? item.noBongkarSusun!.trim()
                    : '-');
          final nama = (item.refNamaMesin ?? '').trim();

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
      AtlasTableColumn<BonggolanHeader>(
        title: 'LOKASI',
        width: _colLokasiWidth,
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

  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    return '${blok ?? ''}${idLokasi ?? ''}';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
