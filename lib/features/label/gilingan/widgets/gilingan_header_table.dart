import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/gilingan_header_model.dart';
import '../view_model/gilingan_view_model.dart';

class GilinganHeaderTable extends StatelessWidget {
  static const _colNoGilinganWidth = 150.0;
  static const _colTanggalWidth = 108.0;
  static const _colBeratWidth = 92.0;
  static const _colLokasiWidth = 96.0;
  static const _colPrintWidth = 72.0;

  final ScrollController scrollController;
  final ValueChanged<GilinganHeader> onItemTap;

  final void Function(GilinganHeader header, Offset globalPosition)
  onItemLongPress;

  final void Function(GilinganHeader header, Offset globalPosition)?
  onPartialTap;

  const GilinganHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemLongPress,
    this.onPartialTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GilinganViewModel>(
      builder: (context, vm, _) {
        return AtlasDataTable<GilinganHeader>(
          columns: _buildColumns(),
          items: vm.items,
          scrollController: scrollController,
          isLoading: vm.isLoading,
          isFetchingMore: vm.isFetchingMore,
          errorMessage: vm.errorMessage,
          errorBuilder: _buildErrorState,
          selectedPredicate: (item) => vm.selectedNoGilingan == item.noGilingan,
          onRowTapWithPosition: (item, globalPosition) {
            onItemTap(item);
            if (item.isPartialBool && onPartialTap != null) {
              onPartialTap!(item, globalPosition);
            }
          },
          onRowLongPress: onItemLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<GilinganHeader>> _buildColumns() {
    return [
      AtlasTableColumn<GilinganHeader>(
        title: 'NO. GILINGAN',
        width: _colNoGilinganWidth,
        cellBuilder: (context, item, rowState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.noGilingan,
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
      AtlasTableColumn<GilinganHeader>(
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
      AtlasTableColumn<GilinganHeader>(
        title: 'JENIS',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaGilingan ?? '-',
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<GilinganHeader>(
        title: 'BERAT',
        width: _colBeratWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBerat(item.berat),
            style: TextStyle(
              fontSize: 14,
              fontWeight: item.isPartialBool
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: item.isPartialBool ? Colors.red : rowState.textColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<GilinganHeader>(
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
      AtlasTableColumn<GilinganHeader>(
        title: 'LOKASI',
        width: _colLokasiWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            _formatBlokLokasi(item.blok, item.idLokasi),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<GilinganHeader>(
        title: 'PRINT',
        width: _colPrintWidth,
        showDivider: false,
        cellBuilder: (context, item, rowState) {
          return Selector<LabelPrintLockSocketManager, _PrintCellState>(
            selector: (_, locks) => _PrintCellState(
              lock: locks.lockOf(item.noGilingan),
              count: locks.printCountOf(item.noGilingan),
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
