import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';

class SourceChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const SourceChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 3,
      borderWidth: 2,
      showShadow: true,
      customShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          offset: const Offset(0, 1),
          blurRadius: 1,
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.inventory_2_outlined,
            size: 16,
            color: const Color(0xFF6B778C), // N200
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B4D), // N800
              letterSpacing: -0.003,
            ),
          ),
        ],
      ),
    );
  }
}
