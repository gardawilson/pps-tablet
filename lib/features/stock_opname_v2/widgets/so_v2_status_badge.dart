import 'package:flutter/material.dart';

import '../model/so_v2_kategori.dart';

class SoV2StatusBadge extends StatelessWidget {
  final SoV2Status status;

  const SoV2StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }
}
