import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bahan_baku_header.dart';
import '../view_model/bahan_baku_view_model.dart';

class BahanBakuHeaderTable extends StatelessWidget {
  static const _colNoBbWidth = 130.0;
  static const _colTanggalWidth = 110.0;
  static const _colNoPlatWidth = 100.0;

  final ScrollController scrollController;
  final ValueChanged<BahanBakuHeader> onItemTap;
  final void Function(BahanBakuHeader header, Offset globalPosition)?
  onItemLongPress;

  const BahanBakuHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BahanBakuViewModel>(
      builder: (context, vm, _) {
        return AtlasDataTable<BahanBakuHeader>(
          columns: _buildColumns(),
          items: vm.items,
          scrollController: scrollController,
          isLoading: vm.isLoading,
          isFetchingMore: vm.isFetchingMore,
          errorMessage: vm.errorMessage,
          errorBuilder: _buildErrorState,
          selectedPredicate: (item) =>
              vm.selectedNoBahanBaku == item.noBahanBaku,
          onRowTap: onItemTap,
          onRowLongPress: onItemLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<BahanBakuHeader>> _buildColumns() {
    return [
      AtlasTableColumn<BahanBakuHeader>(
        title: 'NO. BB',
        width: _colNoBbWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noBahanBaku,
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
      AtlasTableColumn<BahanBakuHeader>(
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
      AtlasTableColumn<BahanBakuHeader>(
        title: 'SUPPLIER',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaSupplier,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BahanBakuHeader>(
        title: 'NO. PLAT',
        width: _colNoPlatWidth,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noPlat ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
    ];
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
