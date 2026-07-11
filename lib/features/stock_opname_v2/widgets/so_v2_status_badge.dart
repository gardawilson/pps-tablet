import 'package:flutter/material.dart';

import '../model/so_v2_kategori.dart';

class SoV2StatusBadge extends StatelessWidget {
  final SoV2Status status;

  const SoV2StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: status == SoV2Status.inProgress
            ? const Border(left: BorderSide(color: Color(0xFFF59E0B), width: 3))
            : null,
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
