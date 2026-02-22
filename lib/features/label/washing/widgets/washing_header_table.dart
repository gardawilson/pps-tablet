import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/washing_header_model.dart';
import '../view_model/washing_view_model.dart';

class WashingHeaderTable extends StatelessWidget {
  static const _colNoWashingWidth = 128.0;
  static const _colTanggalWidth = 108.0;
  static const _colLokasiWidth = 96.0;

  final ScrollController scrollController;
  final ValueChanged<WashingHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(WashingHeader header, Offset globalPosition)
  onItemLongPress;

  const WashingHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WashingViewModel>(
      builder: (context, vm, _) {
        return AtlasDataTable<WashingHeader>(
          columns: _buildColumns(),
          items: vm.items,
          scrollController: scrollController,
          isLoading: vm.isLoading,
          isFetchingMore: vm.isFetchingMore,
          errorMessage: vm.errorMessage,
          errorBuilder: _buildErrorState,
          selectedPredicate: (item) => vm.selectedNoWashing == item.noWashing,
          highlightPredicate: _isQCCompleted,
          onRowTap: onItemTap,
          onRowLongPress: onItemLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<WashingHeader>> _buildColumns() {
    return [
      AtlasTableColumn<WashingHeader>(
        title: 'NO. WASHING',
        width: _colNoWashingWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noWashing,
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
      AtlasTableColumn<WashingHeader>(
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
      AtlasTableColumn<WashingHeader>(
        title: 'JENIS',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaJenisPlastik,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<WashingHeader>(
        title: 'PROSES',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          final code = (item.noProduksi ?? '').trim().isNotEmpty
              ? item.noProduksi!.trim()
              : ((item.noBongkarSusun ?? '').trim().isNotEmpty
                    ? item.noBongkarSusun!.trim()
                    : '-');
          final nama = (item.namaMesin ?? '').trim();

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
      AtlasTableColumn<WashingHeader>(
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

  bool _isQCCompleted(WashingHeader item) {
    return (item.density != null) ||
        (item.density2 != null) ||
        (item.density3 != null) ||
        (item.moisture != null) ||
        (item.moisture2 != null) ||
        (item.moisture3 != null);
  }
}
