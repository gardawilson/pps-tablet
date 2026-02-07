import 'package:flutter/material.dart';

class CountBadge extends StatelessWidget {
  final int count;
  final String? singularLabel;
  final String? pluralLabel;

  const CountBadge({
    super.key,
    required this.count,
    this.singularLabel,
    this.pluralLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? (singularLabel ?? 'item')
        : (pluralLabel ?? 'items');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE1E6), // N40
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF42526E), // N300
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
