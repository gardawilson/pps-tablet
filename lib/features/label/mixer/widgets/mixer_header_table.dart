import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/mixer_view_model.dart';
import '../model/mixer_header_model.dart';
import '../../../../core/utils/date_formatter.dart';

class MixerHeaderTable extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<MixerHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(MixerHeader header, Offset globalPosition) onItemLongPress;

  const MixerHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: Consumer<MixerViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vm.errorMessage.isNotEmpty && vm.items.isEmpty) {
                return _buildErrorState(vm.errorMessage);
              }

              return ListView.builder(
                controller: scrollController,
                itemCount: vm.items.length + (vm.isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == vm.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = vm.items[index];
                  final isSelected = vm.selectedNoMixer == item.noMixer;
                  final isEven = index % 2 == 0;

                  return _buildTableRow(
                    context: context,
                    item: item,
                    isSelected: isSelected,
                    isEven: isEven,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================
  // HEADER
  // =========================
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              'NO. MIXER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              'TANGGAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'JENIS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'OUTPUT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'LOKASI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ROW
  // =========================
  Widget _buildTableRow({
    required BuildContext context,
    required MixerHeader item,
    required bool isSelected,
    required bool isEven,
  }) {
    // Warna latar: selected > zebra
    final bgColor = isSelected
        ? Colors.blue.shade50
        : (isEven ? Colors.white : Colors.grey.shade50);

    // ---- OUTPUT: gunakan generic OutputType/OutputCode/OutputNamaMesin ----
    String code = (item.outputCode ?? '').trim();
    String namaOutput = (item.outputNamaMesin ?? '').trim();

    // Fallback kalau server masih kirim legacy fields
    if (code.isEmpty) {
      if ((item.noProduksi ?? '').isNotEmpty) {
        code = item.noProduksi!;
      } else if ((item.noBongkarSusun ?? '').isNotEmpty) {
        code = item.noBongkarSusun!;
      }
    }

    if (namaOutput.isEmpty && (item.namaMesin ?? '').isNotEmpty) {
      namaOutput = item.namaMesin!;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (details) =>
          onItemLongPress(item, details.globalPosition),
      onSecondaryTapDown: (details) =>
          onItemLongPress(item, details.globalPosition),
      child: InkWell(
        onTap: () => onItemTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 4,
              ),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // NO. MIXER
              SizedBox(
                width: 150,
                child: Text(
                  item.noMixer,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                    color:
                    isSelected ? Colors.blue.shade900 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // TANGGAL
              SizedBox(
                width: 130,
                child: Text(
                  formatDateToShortId(item.dateCreate),
                  style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // JENIS (Nama Mixer)
              Expanded(
                child: Text(
                  item.namaMixer,
                  style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // OUTPUT (Kode + Nama Mesin/Bongkar/Inject)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code.isNotEmpty ? code : '-',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (namaOutput.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        namaOutput,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // LOKASI
              SizedBox(
                width: 120,
                child: Text(
                  _formatBlokLokasi(item.blok, item.idLokasi),
                  style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi =
        idLokasi != null && idLokasi.toString().trim().isNotEmpty;

    if (!hasBlok && !hasLokasi) {
      return '-';
    }

    // kalau keduanya ada → gabung tanpa spasi (contoh: A1)
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
