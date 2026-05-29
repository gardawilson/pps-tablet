// lib/features/production/shared/widgets/production_inline_stat.dart
//
// _InlineStat, _MiniMetric — atom widgets untuk menampilkan statistik ringkas.
// Dipakai di grand-total bar dan tile-tile input/output.

import 'package:flutter/material.dart';

/// Menampilkan "Label: Value" dalam satu baris kompak.
class ProductionInlineStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ProductionInlineStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Ikon kecil + teks — dipakai di tile metric (sak, berat, print count, dll.).
class ProductionMiniMetric extends StatelessWidget {
  final IconData icon;
  final String text;

  const ProductionMiniMetric({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
