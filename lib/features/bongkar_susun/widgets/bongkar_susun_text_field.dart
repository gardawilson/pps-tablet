import 'package:flutter/material.dart';

class BongkarSusunTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  // Behavior
  final TextInputType? keyboardType;
  final bool readOnly;     // hanya tidak bisa edit (masih enabled secara visual)
  final bool asText;       // tampil seperti field-baca (tanpa keyboard)
  final bool enabled;      // mengatur enabled/disabled styling & interaksi
  final bool bold;         // font tebal atau normal untuk nilai

  // Opsional UI
  final String? hintText;         // hint khusus untuk TextField
  final String? placeholderText;  // placeholder saat asText & value kosong
  final int maxLines;

  const BongkarSusunTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.asText = false,
    this.enabled = true,
    this.bold = false,
    this.hintText,
    this.placeholderText = '—', // bisa kamu ganti 'BG.XXXXXXXXXX' kalau mau
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseValueStyle = TextStyle(
      fontSize: 16,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: enabled ? theme.colorScheme.onSurface : theme.disabledColor,
    );

    // =========================
    // Mode display-only (asText)
    // =========================
    if (asText) {
      final String display =
      (controller.text.isNotEmpty) ? controller.text : (placeholderText ?? '—');

      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            size: 22,
            color: enabled ? null : theme.disabledColor,
          ),
          enabled: enabled, // mempengaruhi warna border/label
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        child: Text(display, style: baseValueStyle),
      );
    }

    // =========================
    // Default: TextField (input)
    // =========================
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      enabled: enabled, // <-- ini yang benar-benar disable field (greyed)
      maxLines: maxLines,
      style: baseValueStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15),
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          size: 22,
          color: enabled ? null : theme.disabledColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
