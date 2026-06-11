import 'package:flutter/material.dart';

import 'production_small_info_row.dart';
import 'production_status_dot.dart';

class MesinCardData {
  final String namaMesin;
  final bool isActive;
  final String? shiftTimeText;
  final String? namaRegu;
  final String? outputJenisNama;
  final String? namaCetakan;
  final String? namaWarna;
  final String? namaFurnitureMaterial;

  const MesinCardData({
    required this.namaMesin,
    required this.isActive,
    this.shiftTimeText,
    this.namaRegu,
    this.outputJenisNama,
    this.namaCetakan,
    this.namaWarna,
    this.namaFurnitureMaterial,
  });
}

class ProductionMesinCard extends StatelessWidget {
  const ProductionMesinCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final MesinCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = data.isActive
        ? const Color(0xFF86EFAC)
        : const Color(0xFFFCA5A5);

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
                      data.namaMesin,
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
                  ProductionStatusDot(active: data.isActive),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),
              if (data.isActive) ...[
                if (data.shiftTimeText != null &&
                    data.shiftTimeText!.isNotEmpty)
                  ProductionSmallInfoRow(
                    icon: Icons.access_time_outlined,
                    text: data.shiftTimeText!,
                    bold: true,
                  ),
                if ((data.namaRegu ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.groups_outlined,
                    text: data.namaRegu!,
                  ),
                ],
                if ((data.namaCetakan ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.view_in_ar_rounded,
                    text: data.namaCetakan!.trim(),
                    color: const Color(0xFF374151),
                  ),
                ],
                if ((data.namaWarna ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.palette_outlined,
                    text: data.namaWarna!.trim(),
                    color: const Color(0xFF374151),
                  ),
                ],
                if ((data.namaFurnitureMaterial ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.category_outlined,
                    text: data.namaFurnitureMaterial!.trim(),
                    color: const Color(0xFF374151),
                  ),
                ] else if ((data.outputJenisNama ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ProductionSmallInfoRow(
                    icon: Icons.inventory_2_outlined,
                    text: data.outputJenisNama!.trim(),
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
