import 'package:flutter/material.dart';

import '../../shared/widgets/production_small_info_row.dart';
import '../../shared/widgets/production_status_dot.dart';
import '../model/washing_production_model.dart';

/// Kartu mesin untuk panel kiri pada WashingProductionMesinScreen.
/// Menampilkan nama mesin, status aktif/nonaktif, shift & jam aktif,
/// operator, dan jenis output.
class WashingMesinCard extends StatelessWidget {
  const WashingMesinCard({
    super.key,
    required this.mesin,
    required this.onTap,
  });

  final WashingMesinInfo mesin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final borderColor =
        active ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mesin.namaMesin,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ProductionStatusDot(active: active),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),
              if (active) ...[
                if (mesin.shift != null ||
                    mesin.hourStart != null ||
                    mesin.hourEnd != null)
                  ProductionSmallInfoRow(
                    icon: Icons.access_time_outlined,
                    text: [
                      if (mesin.shift != null) 'Shift ${mesin.shift}',
                      '${mesin.hourStart ?? '--:--'} – ${mesin.hourEnd ?? '--:--'}',
                    ].join('  |  '),
                    bold: true,
                  ),
                if ((mesin.namaRegu ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.groups_outlined,
                    text: mesin.namaRegu!,
                  ),
                ],
                if (mesin.outputJenisNama != null &&
                    mesin.outputJenisNama!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.inventory_2_outlined,
                    text: mesin.outputJenisNama!.trim(),
                    color: const Color(0xFF374151),
                  ),
                ],
                if (mesin.isBlower == true) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.air,
                    text: 'Blower',
                    color: const Color(0xFF0369A1),
                    bold: true,
                  ),
                ],
              ] else
                const Text(
                  'Belum aktif',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFB91C1C),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
