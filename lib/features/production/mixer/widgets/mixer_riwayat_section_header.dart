import 'package:flutter/material.dart';

import '../../shared/widgets/production_filter_chip.dart';
import '../model/mixer_production_model.dart';

class MixerRiwayatSectionHeader extends StatelessWidget {
  const MixerRiwayatSectionHeader({
    super.key,
    required this.mesinList,
    required this.selectedIdMesin,
    required this.onFilterChanged,
  });

  final List<MixerMesinInfo> mesinList;
  final int? selectedIdMesin;
  final ValueChanged<int?> onFilterChanged;

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
