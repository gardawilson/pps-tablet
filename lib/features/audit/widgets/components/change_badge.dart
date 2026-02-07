import 'package:flutter/material.dart';

class ChangeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String oldValue;
  final String newValue;

  const ChangeBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBE6), // R50
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFFDE350B), // R400
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDE350B), // R400
              letterSpacing: 0.3,
            ),
          ),
          Text(
            oldValue,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B778C), // N200
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              size: 10,
              color: Color(0xFFDE350B), // R400
            ),
          ),
          Text(
            newValue,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDE350B), // R400
            ),
          ),
        ],
      ),
    );
  }
}
