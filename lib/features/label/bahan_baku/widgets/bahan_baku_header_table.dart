// lib/features/production/bahan_baku/widgets/bahan_baku_header_table.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/bahan_baku_header.dart';
import '../view_model/bahan_baku_view_model.dart';
import '../../../../core/utils/date_formatter.dart';

class BahanBakuHeaderTable extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<BahanBakuHeader> onItemTap;

  /// Kirim header + posisi global saat long-press (untuk popover)
  final void Function(BahanBakuHeader header, Offset globalPosition)? onItemLongPress;

  const BahanBakuHeaderTable({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: Consumer<BahanBakuViewModel>(
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
                  final isSelected = vm.selectedNoBahanBaku == item.noBahanBaku;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ⬅️ padding dikurangi
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 140, // ⬅️ dari 180 → 140
            child: Text(
              'NO. BB',  // ⬅️ singkat dari "NO. BAHAN BAKU"
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13, // ⬅️ dari 14 → 13
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 90, // ⬅️ dari 130 → 90
            child: Text(
              'TANGGAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2, // ⬅️ tambah flex
            child: Text(
              'SUPPLIER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 100, // ⬅️ dari 140 → 100
            child: Text(
              'NO. PLAT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1, // ⬅️ dari fixed 150 → Expanded
            child: Text(
              'DIBUAT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
    required BahanBakuHeader item,
    required bool isSelected,
    required bool isEven,
  }) {
    final bgColor = isSelected
        ? Colors.blue.shade50
        : (isEven ? Colors.white : Colors.grey.shade50);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: onItemLongPress != null
          ? (details) => onItemLongPress!(item, details.globalPosition)
          : null,
      onSecondaryTapDown: onItemLongPress != null
          ? (details) => onItemLongPress!(item, details.globalPosition)
          : null,
      child: InkWell(
        onTap: () => onItemTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ⬅️ padding dikurangi
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
                width: 140, // ⬅️ sesuaikan dengan header
                child: Text(
                  item.noBahanBaku,
                  style: TextStyle(
                    fontSize: 14, // ⬅️ dari 15 → 14
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  formatDateToShortId(item.dateCreate),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.namaSupplier,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  item.noPlat ?? '-',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  item.createBy ?? '-',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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