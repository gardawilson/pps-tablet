import 'package:flutter/material.dart';

/// Baris info kecil dengan icon + teks, dipakai di dalam kartu mesin.
/// Contoh: jam kerja, nama operator, jenis output.
class ProductionSmallInfoRow extends StatelessWidget {
  const ProductionSmallInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.bold = false,
    this.color,
  });

  final IconData icon;
  final String text;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xFF4B5563);
    return Row(
      children: [
        Icon(icon, size: 10, color: textColor),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
