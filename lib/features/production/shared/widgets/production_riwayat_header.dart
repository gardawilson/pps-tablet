import 'package:flutter/material.dart';

import 'production_filter_chip.dart';

class MesinFilterItem {
  final int idMesin;
  final String namaMesin;

  const MesinFilterItem({required this.idMesin, required this.namaMesin});
}

class ProductionRiwayatHeader extends StatelessWidget {
  const ProductionRiwayatHeader({
    super.key,
    required this.mesinList,
    required this.selectedIdMesin,
    required this.onFilterChanged,
    this.onToggle,
    this.isExpanded = true,
  });

  final List<MesinFilterItem> mesinList;
  final int? selectedIdMesin;
  final ValueChanged<int?> onFilterChanged;
  final VoidCallback? onToggle;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (onToggle != null) ...[
                    Tooltip(
                      message: 'Sembunyikan Riwayat',
                      waitDuration: const Duration(milliseconds: 400),
                      child: IconButton(
                        onPressed: onToggle,
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          size: 16,
                        ),
                        color: const Color(0xFF9CA3AF),
                        hoverColor: const Color(0xFFEFF6FF),
                        highlightColor: const Color(0xFFDBEAFE),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Text(
                    'Riwayat Produksi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ProductionFilterChip(
                    label: 'Semua',
                    selected: selectedIdMesin == null,
                    onTap: () => onFilterChanged(null),
                  ),
                ],
              ),
            ),
          ),
          if (mesinList.isNotEmpty)
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                children: mesinList
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ProductionFilterChip(
                          label: m.namaMesin,
                          selected: selectedIdMesin == m.idMesin,
                          onTap: () => onFilterChanged(m.idMesin),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
