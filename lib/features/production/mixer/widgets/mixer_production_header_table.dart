import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/mixer_production_model.dart';
import '../view_model/mixer_production_view_model.dart';

class MixerProductionHeaderTable extends StatelessWidget {
  static const _colNoProduksiWidth = 160.0;
  static const _colTanggalWidth = 110.0;
  static const _colShiftWidth = 70.0;
  static const _colMesinWidth = 180.0;
  static const _colOperatorWidth = 200.0;
  static const _colJamKerjaWidth = 100.0;
  static const _colJamWidth = 140.0;
  static const _colHmWidth = 80.0;
  static const _colAnggotaWidth = 140.0;

  final String? selectedNoProduksi;
  final ValueChanged<MixerProduction> onRowTap;
  final void Function(MixerProduction row, Offset globalPosition)
  onRowLongPress;

  const MixerProductionHeaderTable({
    super.key,
    required this.selectedNoProduksi,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerProductionViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<MixerProduction>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) => item.noProduksi == selectedNoProduksi,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<MixerProduction>> _buildColumns() {
    return [
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
        title: 'JAM KERJA',
        width: _colJamKerjaWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            '${item.jamKerja} jam',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
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
      AtlasTableColumn<MixerProduction>(
        title: 'ANGGOTA/HADIR',
        width: _colAnggotaWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            '${item.jmlhAnggota ?? '-'}/${item.hadir ?? '-'}',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
    ];
  }
}
