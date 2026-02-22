import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/inject_production_model.dart';
import '../view_model/inject_production_view_model.dart';

class InjectProductionHeaderTable extends StatelessWidget {
  static const _colNoProduksiWidth = 170.0;
  static const _colTanggalWidth = 110.0;
  static const _colShiftWidth = 70.0;
  static const _colMesinWidth = 180.0;
  static const _colOperatorWidth = 200.0;
  static const _colJamWidth = 100.0;
  static const _colJamKerjaWidth = 140.0;
  static const _colHmWidth = 80.0;
  static const _colBeratWidth = 100.0;

  final String? selectedNoProduksi;
  final ValueChanged<InjectProduction> onRowTap;
  final void Function(InjectProduction row, Offset globalPosition)
  onRowLongPress;

  const InjectProductionHeaderTable({
    super.key,
    required this.selectedNoProduksi,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<InjectProductionViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<InjectProduction>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) => item.noProduksi == selectedNoProduksi,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<InjectProduction>> _buildColumns() {
    return [
      AtlasTableColumn<InjectProduction>(
        title: 'NO. PRODUKSI',
        width: _colNoProduksiWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noProduksi,
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
      AtlasTableColumn<InjectProduction>(
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
      AtlasTableColumn<InjectProduction>(
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
      AtlasTableColumn<InjectProduction>(
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
      AtlasTableColumn<InjectProduction>(
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
      AtlasTableColumn<InjectProduction>(
        title: 'JAM',
        width: _colJamWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.jam > 0 ? '${item.jam} jam' : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<InjectProduction>(
        title: 'JAM KERJA',
        width: _colJamKerjaWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            '${item.hourStart ?? '--:--'} - ${item.hourEnd ?? '--:--'}',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<InjectProduction>(
        title: 'HM',
        width: _colHmWidth,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.hourMeter != null ? '${item.hourMeter}' : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<InjectProduction>(
        title: 'BERAT (kg)',
        width: _colBeratWidth,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.beratProdukHasilTimbang != null
                ? '${item.beratProdukHasilTimbang}'
                : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
    ];
  }
}
