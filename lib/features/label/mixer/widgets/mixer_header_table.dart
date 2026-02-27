import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/mixer_header_model.dart';
import '../view_model/mixer_view_model.dart';

class MixerHeaderTable extends StatelessWidget {
  static const _colNoMixerWidth = 120.0;
  static const _colTanggalWidth = 108.0;
  static const _colLokasiWidth = 96.0;
  static const _colPrintWidth = 72.0;

  final ScrollController scrollController;
  final ValueChanged<MixerHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(MixerHeader header, Offset globalPosition)
  onItemLongPress;

  const MixerHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerViewModel>(
      builder: (context, vm, _) {
        return AtlasDataTable<MixerHeader>(
          columns: _buildColumns(),
          items: vm.items,
          scrollController: scrollController,
          isLoading: vm.isLoading,
          isFetchingMore: vm.isFetchingMore,
          errorMessage: vm.errorMessage,
          errorBuilder: _buildErrorState,
          selectedPredicate: (item) => vm.selectedNoMixer == item.noMixer,
          highlightPredicate: _isQCCompleted,
          onRowTap: onItemTap,
          onRowLongPress: onItemLongPress,
        );
      },
    );
  }

  List<AtlasTableColumn<MixerHeader>> _buildColumns() {
    return [
      AtlasTableColumn<MixerHeader>(
        title: 'NO. MIXER',
        width: _colNoMixerWidth,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.noMixer,
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
      AtlasTableColumn<MixerHeader>(
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
      AtlasTableColumn<MixerHeader>(
        title: 'JENIS',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          return Text(
            item.namaMixer,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<MixerHeader>(
        title: 'OUTPUT',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, item, rowState) {
          final output = _resolveOutput(item);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                output.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rowState.isSelected
                      ? const Color(0xFF0C66E4)
                      : Colors.grey.shade900,
                ),
                softWrap: true,
              ),
              if (output.name.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  output.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: rowState.isSelected
                        ? rowState.textColor
                        : Colors.grey.shade600,
                  ),
                  softWrap: true,
                ),
              ],
            ],
          );
        },
      ),
      AtlasTableColumn<MixerHeader>(
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
      AtlasTableColumn<MixerHeader>(
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

  _OutputData _resolveOutput(MixerHeader item) {
    String code = (item.outputCode ?? '').trim();
    String name = (item.outputNamaMesin ?? '').trim();

    if (code.isEmpty) {
      if ((item.noProduksi ?? '').isNotEmpty) {
        code = item.noProduksi!;
      } else if ((item.noBongkarSusun ?? '').isNotEmpty) {
        code = item.noBongkarSusun!;
      }
    }

    if (name.isEmpty && (item.namaMesin ?? '').isNotEmpty) {
      name = item.namaMesin!;
    }

    return _OutputData(code: code.isNotEmpty ? code : '-', name: name);
  }

  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    return '${blok ?? ''}${idLokasi ?? ''}';
  }

  bool _isQCCompleted(MixerHeader item) {
    return (item.moisture != null) ||
        (item.moisture2 != null) ||
        (item.moisture3 != null) ||
        (item.minMeltTemp != null) ||
        (item.maxMeltTemp != null) ||
        (item.mfi != null);
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

class _OutputData {
  final String code;
  final String name;

  const _OutputData({required this.code, required this.name});
}
