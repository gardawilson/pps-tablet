import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_family_view_model.dart';

class AscendFamilySection extends StatelessWidget {
  final int? selectedFamilyID;
  final ValueChanged<int> onFamilySelected; // parent yang fetch & clear controller

  const AscendFamilySection({
    super.key,
    required this.selectedFamilyID,
    required this.onFamilySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.category_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Familie Produk',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1F2937))),
            ]),
          ),
          Expanded(
            child: Consumer<StockOpnameFamilyViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3),
                      SizedBox(height: 12),
                      Text('Memuat familie...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ]),
                  );
                }
                if (vm.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (vm.families.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.folder_open_outlined, color: Color(0xFF9CA3AF), size: 48),
                      SizedBox(height: 8),
                      Text("Tidak ada family", style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ]),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: vm.families.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final family = vm.families[index];
                    final isSelected = selectedFamilyID == family.familyID;
                    final progress = family.totalItem > 0 ? family.completeItem / family.totalItem : 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        dense: true,
                        title: Text(
                          family.familyName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1F2937),
                          ),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                              child: Text("${family.completeItem}/${family.totalItem} items",
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ),
                            Text("${(progress * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: progress == 1.0 ? Colors.green.shade600 : const Color(0xFF3B82F6),
                                )),
                          ]),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0 ? Colors.green.shade500 : const Color(0xFF3B82F6),
                            ),
                            minHeight: 3,
                          ),
                        ]),
                        onTap: () => onFamilySelected(family.familyID),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
