import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/bonggolan_view_model.dart';
import '../model/bonggolan_header_model.dart';
import '../../../../core/utils/date_formatter.dart';

class BonggolanHeaderTable extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<BonggolanHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(BonggolanHeader header, Offset globalPosition) onItemLongPress;

  const BonggolanHeaderTable({
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
          child: Consumer<BonggolanViewModel>(
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
                  final isSelected = vm.selectedNoBonggolan == item.noBonggolan;
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 150,
            child: Text(
              'NO. BONGGOLAN',
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
          SizedBox(
            width: 100,
            child: Text(
              'BERAT',
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
              'PROSES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 100,
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

  Widget _buildTableRow({
    required BuildContext context,
    required BonggolanHeader item,
    required bool isSelected,
    required bool isEven,
  }) {
    // Warna latar: selected > zebra
    final bgColor = isSelected
        ? Colors.blue.shade50
        : (isEven ? Colors.white : Colors.grey.shade50);

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
              SizedBox(
                width: 150,
                child: Text(
                  item.noBonggolan,
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
              SizedBox(
                width: 130,
                child: Text(
                  formatDateToShortId(item.dateCreate),
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  item.namaBonggolan ?? '-',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  item.berat.toString(),
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  displayMesinOrBongkar(item),
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  _formatBlokLokasi(item.blok, item.idLokasi),
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String displayMesinOrBongkar(BonggolanHeader i) {
    String? pick(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

    // Prefer nama mesin Inject → Broker; fallback ke NoBongkarSusun
    return pick(i.injectNamaMesin)
        ?? pick(i.brokerNamaMesin)
        ?? pick(i.noBongkarSusun)
        ?? '-';
  }



  String _formatBlokLokasi(String? blok, dynamic idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi.toString().trim().isNotEmpty;

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
