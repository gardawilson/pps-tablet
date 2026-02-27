import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
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

  /// Kirim header + posisi global saat long-press (untuk row popover)
  final void Function(GilinganHeader header, Offset globalPosition)
  onItemLongPress;

  /// callback ketika row partial di-tap
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
          return Row(
            children: [
              Expanded(
                child: Text(
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
              ),
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
          final count = item.hasBeenPrinted;
          if (count == 0) {
            return Text(
              '—',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
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
