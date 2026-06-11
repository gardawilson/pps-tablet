import 'package:flutter/material.dart';

import '../utils/format.dart';
import 'production_inline_stat.dart';

class ProductionRejectOutputTile extends StatelessWidget {
  const ProductionRejectOutputTile({
    super.key,
    required this.labelCode,
    required this.namaJenis,
    required this.berat,
    required this.isPrinted,
    this.pcs,
    this.accentColor = const Color(0xFF00695C),
    this.onTap,
  });

  final String labelCode;
  final String namaJenis;
  final double berat;
  final bool isPrinted;
  final int? pcs;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E6EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      labelCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D23),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.print_outlined,
                    size: 11,
                    color: isPrinted ? accentColor : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                namaJenis,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  ProductionMiniMetric(
                    icon: Icons.scale_outlined,
                    text: '${num2(berat)} kg',
                  ),
                  if (pcs != null)
                    ProductionMiniMetric(
                      icon: Icons.inventory_2_outlined,
                      text: '$pcs pcs',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
