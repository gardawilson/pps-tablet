import 'package:flutter/material.dart';

/// Dot indikator status aktif/tidak aktif pada kartu mesin.
/// Hijau = aktif, Merah = tidak aktif.
class ProductionStatusDot extends StatelessWidget {
  const ProductionStatusDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
