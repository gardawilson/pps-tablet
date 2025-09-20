import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_ascend_view_model.dart';
import '../filter_section/search_label_widget.dart';

class AscendFilterSection extends StatelessWidget {
  final String noSO;
  final int? selectedFamilyID;
  final VoidCallback onSavePressed;
  const AscendFilterSection({
    super.key,
    required this.noSO,
    required this.selectedFamilyID,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SearchLabelWidget(
                onSearch: (q) {
                  if (selectedFamilyID != null) {
                    context.read<StockOpnameAscendViewModel>()
                        .fetchAscendItems(noSO, selectedFamilyID!, keyword: q);
                  }
                },
                onClear: () {
                  if (selectedFamilyID != null) {
                    context.read<StockOpnameAscendViewModel>()
                        .fetchAscendItems(noSO, selectedFamilyID!, keyword: '');
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onSavePressed,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text("Simpan Data", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
