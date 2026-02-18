import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QcDialogPalette {
  static const primary = Color(0xFF1565C0);
  static const primarySubtle = Color(0xFFE9F2FF);
  static const border = Color(0xFFDCDFE4);
  static const text = Color(0xFF172B4D);
  static const subtleText = Color(0xFF44546F);
  static const surface = Color(0xFFF7F8F9);
}

class QcDialogShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  const QcDialogShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.onCancel,
    required this.onSubmit,
    this.submitLabel = 'Simpan QC',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: QcDialogPalette.primarySubtle,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          border: Border(bottom: BorderSide(color: QcDialogPalette.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: QcDialogPalette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.science_outlined,
                size: 20,
                color: QcDialogPalette.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: QcDialogPalette.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QcDialogPalette.subtleText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: content,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: QcDialogPalette.subtleText,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: QcDialogPalette.border),
            ),
          ),
          onPressed: onCancel,
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: QcDialogPalette.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onSubmit,
          icon: const Icon(Icons.save_outlined, size: 20),
          label: Text(submitLabel),
        ),
      ],
    );
  }
}

class QcSectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const QcSectionTitle({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: QcDialogPalette.subtleText),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: QcDialogPalette.subtleText,
          ),
        ),
      ],
    );
  }
}

class QcDecimalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? suffix;

  const QcDecimalField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: QcDialogPalette.text,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: qcInputDecoration(label: label, suffix: suffix),
    );
  }
}

InputDecoration qcInputDecoration({
  required String label,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: QcDialogPalette.subtleText,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    suffixText: suffix,
    suffixStyle: const TextStyle(
      color: QcDialogPalette.subtleText,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: QcDialogPalette.surface,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: QcDialogPalette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: QcDialogPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: QcDialogPalette.primary),
    ),
  );
}
