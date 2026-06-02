import 'package:flutter/material.dart';

/// Badge kecil untuk menampilkan count + label (e.g. "3 Aktif", "2 Tidak Aktif").
/// Dipakai di section header mesin pada semua modul production.
class ProductionStatBadge extends StatelessWidget {
  const ProductionStatBadge({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  final int count;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
