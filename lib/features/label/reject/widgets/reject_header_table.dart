import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/reject_header_model.dart';

class RejectHeaderTable extends StatelessWidget {
  final PagingController<int, RejectHeader> pagingController;
  final String? selectedNoReject;
  final ValueChanged<RejectHeader>? onItemTap;
  final void Function(RejectHeader header, Offset globalPosition)?
  onItemLongPress;
  final ValueChanged<RejectHeader>? onPartialTap;

  const RejectHeaderTable({
    super.key,
    required this.pagingController,
    this.selectedNoReject,
    this.onItemTap,
    this.onItemLongPress,
    this.onPartialTap,
  });

  @override
  Widget build(BuildContext context) {
    return AtlasPagedDataTable<RejectHeader>(
      pagingController: pagingController,
      columns: _buildColumns(),
      selectedPredicate: (row) => row.noReject == selectedNoReject,
      onRowTap: (row) {
        onItemTap?.call(row);
        if (row.isPartialBool && onPartialTap != null) {
          onPartialTap!(row);
        }
      },
      onRowLongPress: (row, pos) => onItemLongPress?.call(row, pos),
    );
  }

  List<AtlasTableColumn<RejectHeader>> _buildColumns() {
    return [
      AtlasTableColumn<RejectHeader>(
        title: 'NO. LABEL',
        width: 170,
        cellBuilder: (context, item, rowState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.noReject,
                softWrap: true,
                style: TextStyle(
                  fontWeight: rowState.isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: rowState.isSelected
                      ? const Color(0xFF0C66E4)
                      : Colors.black87,
                ),
              ),
              if (item.used) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFB71C1C).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Terpakai',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB71C1C),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      AtlasTableColumn<RejectHeader>(
        title: 'TANGGAL',
        width: 130,
        cellBuilder: (context, item, rowState) {
          return Text(
            formatDateToShortId(item.dateCreate),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<RejectHeader>(
        title: 'JENIS',
        width: 275,
        cellBuilder: (context, item, rowState) {
          final nama = (item.namaReject ?? '').trim();
          return Text(
            nama.isEmpty ? '-' : nama,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<RejectHeader>(
        title: 'PROSES',
        width: 200,
        cellBuilder: (context, item, rowState) {
          final code = item.outputCode ?? '-';
          final nama = (item.outputNamaMesin ?? '').trim();

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
      AtlasTableColumn<RejectHeader>(
        title: 'BERAT',
        width: 100,
        headerAlign: TextAlign.right,
        cellAlignment: Alignment.centerRight,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBerat(item.berat),
            style: TextStyle(
              fontSize: 14,
              fontWeight: item.isPartialBool
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: item.isPartialBool ? Colors.red : rowState.textColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<RejectHeader>(
        title: 'LOKASI',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBlokLokasi(item.blok, item.idLokasi),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<RejectHeader>(
        title: 'PRINT',
        width: 72,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Selector<LabelPrintLockSocketManager, _PrintCellState>(
            selector: (_, locks) => _PrintCellState(
              lock: locks.lockOf(item.noReject),
              count: locks.printCountOf(item.noReject),
            ),
            builder: (_, state, __) {
              final lock = state.lock;
              if (lock != null) {
                return Tooltip(
                  message: 'Sedang diprint oleh ${lock.displayUser}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB26A00).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFB26A00).withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Text(
                      'Printing',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB26A00),
                      ),
                    ),
                  ),
                );
              }

              final count = state.count ?? item.hasBeenPrinted;
              if (count == 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C66E4).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0C66E4).withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.print_rounded,
                      size: 12,
                      color: Color(0xFF0C66E4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${count}x',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0C66E4),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ];
  }

  String _formatBerat(double? v) {
    if (v == null) return '-';
    return v.toStringAsFixed(2);
  }

  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    return '${blok ?? ''}${idLokasi ?? ''}';
  }
}

class _PrintCellState {
  final LabelPrintLockInfo? lock;
  final int? count;

  const _PrintCellState({required this.lock, required this.count});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PrintCellState &&
        other.lock == lock &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(lock, count);
}
