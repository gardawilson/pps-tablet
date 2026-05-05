import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_ascend_view_model.dart';
import '../../../view_model/stock_opname_family_view_model.dart';
import '../filter_section/search_label_widget.dart';

class AscendFilterSection extends StatelessWidget {
  static const _primary = Color(0xFF0D47A1);
  static const _success = Color(0xFF0A7349);
  static const _border = Color(0xFFE2E6EE);
  static const _surfaceMuted = Color(0xFFF8F9FB);
  static const _textPrimary = Color(0xFF1A2340);
  static const _textSec = Color(0xFF4A5568);

  final String noSO;
  final String tgl;
  final int? selectedFamilyID;
  final VoidCallback onSavePressed;
  const AscendFilterSection({
    super.key,
    required this.noSO,
    required this.tgl,
    required this.selectedFamilyID,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  noSO,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tgl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSec, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Consumer<StockOpnameFamilyViewModel>(
            builder: (context, vm, _) {
              final totalItems = vm.families.fold<int>(
                0,
                (sum, family) => sum + family.totalItem,
              );
              final completeItems = vm.families.fold<int>(
                0,
                (sum, family) => sum + family.completeItem,
              );

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _success.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: _success,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completeItems/$totalItems',
                      style: const TextStyle(
                        color: _success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
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
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onSavePressed,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text("Simpan Data"),
            ),
          ),
        ],
      ),
    );
  }
}
