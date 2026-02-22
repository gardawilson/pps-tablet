import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/packing_production_model.dart';
import '../view_model/packing_production_view_model.dart';

class PackingProductionHeaderTable extends StatelessWidget {
  static const _colNoPackingWidth = 160.0;
  static const _colTanggalWidth = 130.0;
  static const _colShiftWidth = 70.0;
  static const _colMesinWidth = 180.0;
  static const _colOperatorWidth = 200.0;
  static const _colJamKerjaWidth = 100.0;
  static const _colJamWidth = 140.0;
  static const _colHmWidth = 130.0;

  final String? selectedNoPacking;
  final ValueChanged<PackingProduction> onRowTap;
  final void Function(PackingProduction row, Offset globalPosition)
  onRowLongPress;

  const PackingProductionHeaderTable({
    super.key,
    required this.selectedNoPacking,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProductionViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<PackingProduction>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) => item.noPacking == selectedNoPacking,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<PackingProduction>> _buildColumns() {
    return [
      AtlasTableColumn<PackingProduction>(
        title: 'NO. PACKING',
        width: _colNoPackingWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noPacking,
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
      AtlasTableColumn<PackingProduction>(
        title: 'TANGGAL',
        width: _colTanggalWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            formatDateToShortId(item.tglProduksi),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'SHIFT',
        width: _colShiftWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            '${item.shift}',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'MESIN',
        width: _colMesinWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaMesin,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'OPERATOR',
        width: _colOperatorWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaOperator,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'JAM KERJA',
        width: _colJamKerjaWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.jamKerja != null ? '${item.jamKerja} jam' : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'JAM',
        width: _colJamWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            '${item.hourStart ?? '--:--'} - ${item.hourEnd ?? '--:--'}',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<PackingProduction>(
        title: 'HM',
        width: _colHmWidth,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.hourMeter != null ? '${item.hourMeter}' : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
    ];
  }
}
