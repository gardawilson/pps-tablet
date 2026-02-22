import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bj_jual_model.dart';
import '../view_model/bj_jual_view_model.dart';

class BJJualHeaderTable extends StatelessWidget {
  static const _colNoBJJualWidth = 170.0;
  static const _colTanggalWidth = 130.0;
  static const _colPembeliWidth = 260.0;
  static const _colRemarkWidth = 300.0;

  final String? selectedNoBJJual;
  final ValueChanged<BJJual> onRowTap;
  final void Function(BJJual row, Offset globalPosition) onRowLongPress;

  const BJJualHeaderTable({
    super.key,
    required this.selectedNoBJJual,
    required this.onRowTap,
    required this.onRowLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BJJualViewModel>(
      builder: (context, vm, _) {
        return AtlasPagedDataTable<BJJual>(
          pagingController: vm.pagingController,
          columns: _buildColumns(),
          selectedPredicate: (item) => item.noBJJual == selectedNoBJJual,
          onRowTap: onRowTap,
          onRowLongPress: onRowLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<BJJual>> _buildColumns() {
    return [
      AtlasTableColumn<BJJual>(
        title: 'NO. BJ JUAL',
        width: _colNoBJJualWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noBJJual,
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
      AtlasTableColumn<BJJual>(
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
      AtlasTableColumn<BJJual>(
        title: 'PEMBELI',
        width: _colPembeliWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaPembeli.isNotEmpty ? item.namaPembeli : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BJJual>(
        title: 'REMARK',
        width: _colRemarkWidth,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          final remark = item.remark?.trim();
          return Text(
            (remark != null && remark.isNotEmpty) ? remark : '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
    ];
  }
}
