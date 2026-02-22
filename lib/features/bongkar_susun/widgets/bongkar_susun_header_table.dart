import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bongkar_susun_model.dart';
import '../view_model/bongkar_susun_view_model.dart';

class BongkarSusunHeaderTable extends StatelessWidget {
  static const _colNoBsWidth = 180.0;
  static const _colTanggalWidth = 130.0;
  static const _colCreatedByWidth = 130.0;
  static const _colCatatanWidth = 300.0;

  final String? selectedNoBongkarSusun;
  final ValueChanged<BongkarSusun> onRowTap;
  final void Function(BongkarSusun row, Offset globalPosition) onRowLongPress;

  const BongkarSusunHeaderTable({
    super.key,
    required this.selectedNoBongkarSusun,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BongkarSusunViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<BongkarSusun>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) =>
              item.noBongkarSusun == selectedNoBongkarSusun,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<BongkarSusun>> _buildColumns() {
    return [
      AtlasTableColumn<BongkarSusun>(
        title: 'NO. BS',
        width: _colNoBsWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noBongkarSusun,
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
      AtlasTableColumn<BongkarSusun>(
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
      AtlasTableColumn<BongkarSusun>(
        title: 'CREATED BY',
        width: _colCreatedByWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.username ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          );
        },
      ),
      AtlasTableColumn<BongkarSusun>(
        title: 'CATATAN',
        width: _colCatatanWidth,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.note ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
    ];
  }
}
