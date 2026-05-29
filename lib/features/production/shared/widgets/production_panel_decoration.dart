// lib/features/production/shared/widgets/production_panel_decoration.dart
//
// Shared UI primitives — warna & dekorasi panel produksi.
// Dipakai oleh semua InputScreen (broker, washing, dsb.).

import 'package:flutter/material.dart';

// ── Warna default (bisa di-override oleh tiap fitur) ─────────────────────────
const kProductionPrimary = Color(0xFF1E6FD9);
const kProductionSurface = Color(0xFFF8F9FB);
const kProductionBorder = Color(0xFFE2E6EA);
const kProductionOutput = Color(0xFF0A7349);
const kProductionRadius = 12.0;

// ── Dekorasi panel kartu ──────────────────────────────────────────────────────
BoxDecoration productionPanelDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(kProductionRadius),
  border: Border.all(color: borderColor ?? kProductionBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.025),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ],
);

// ── Header row dalam panel (ikon + judul) ─────────────────────────────────────
Widget productionSectionHeader(
  IconData icon,
  String title, {
  Color? iconColor,
  Color primaryColor = kProductionPrimary,
}) {
  final color = iconColor ?? primaryColor;
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1D23),
        ),
      ),
    ],
  );
}
