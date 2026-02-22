import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/sortir_reject_production_model.dart';
import '../view_model/sortir_reject_production_view_model.dart';

class SortirRejectProductionHeaderTable extends StatelessWidget {
  static const _colNoBJSortirWidth = 170.0;
  static const _colTanggalWidth = 130.0;
  static const _colWarehouseWidth = 140.0;
  static const _colUserWidth = 160.0;

  final String? selectedNoBJSortir;
  final ValueChanged<SortirRejectProduction> onRowTap;
  final void Function(SortirRejectProduction row, Offset globalPosition)
  onRowLongPress;

  const SortirRejectProductionHeaderTable({
    super.key,
    required this.selectedNoBJSortir,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SortirRejectProductionViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<SortirRejectProduction>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) => item.noBJSortir == selectedNoBJSortir,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<SortirRejectProduction>> _buildColumns() {
    return [
      AtlasTableColumn<SortirRejectProduction>(
        title: 'NO. BJ SORTIR',
        width: _colNoBJSortirWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noBJSortir,
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
      AtlasTableColumn<SortirRejectProduction>(
        title: 'TANGGAL',
        width: _colTanggalWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            formatDateToShortId(item.tanggal),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<SortirRejectProduction>(
        title: 'WAREHOUSE',
        width: _colWarehouseWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaWarehouse.isNotEmpty ? item.namaWarehouse : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<SortirRejectProduction>(
        title: 'USER',
        width: _colUserWidth,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.username.isNotEmpty ? item.username : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
    ];
  }
}
