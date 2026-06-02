import 'package:flutter/material.dart';

import '../../shared/widgets/production_small_info_row.dart';
import '../../shared/widgets/production_status_dot.dart';
import '../model/broker_production_model.dart';

/// Kartu mesin untuk panel kiri pada BrokerProductionMesinScreen.
/// Menampilkan nama mesin, status aktif/nonaktif, shift & jam aktif,
/// operator, dan jenis output.
class BrokerMesinCard extends StatelessWidget {
  const BrokerMesinCard({
    super.key,
    required this.mesin,
    required this.onTap,
  });

  final BrokerMesinInfo mesin;
  final VoidCallback onTap;

  BrokerProduksiItem? _currentItem() {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    TimeOfDay? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      final parts = s.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    for (final p in mesin.produksiList) {
      final start = parse(p.hourStart);
      final end = parse(p.hourEnd);
      if (start == null || end == null) continue;
      final s = start.hour * 60 + start.minute;
      final e = end.hour * 60 + end.minute;
      final inRange =
          s <= e ? nowMin >= s && nowMin < e : nowMin >= s || nowMin < e;
      if (inRange) return p;
    }
    return mesin.produksiList.isNotEmpty ? mesin.produksiList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final current = active ? _currentItem() : null;
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
              if (current != null) ...[
                if (current.shift != null ||
                    current.hourStart != null ||
                    current.hourEnd != null)
                  ProductionSmallInfoRow(
                    icon: Icons.access_time_outlined,
                    text: [
                      if (current.shift != null) 'Shift ${current.shift}',
                      '${current.hourStart ?? '--:--'} – ${current.hourEnd ?? '--:--'}',
                    ].join('  |  '),
                    bold: true,
                  ),
                if ((current.namaRegu ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.groups_outlined,
                    text: current.namaRegu!,
                  ),
                ],
                if (current.outputJenisNama != null &&
                    current.outputJenisNama!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.inventory_2_outlined,
                    text: current.outputJenisNama!.trim(),
                    color: const Color(0xFF374151),
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
