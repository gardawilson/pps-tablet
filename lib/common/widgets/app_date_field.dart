import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable date picker text field
/// - Dipakai dengan TextEditingController agar gampang integrasi ke MVVM/form
/// - Klik field membuka showDatePicker
/// - Punya tombol clear & icon kalender
class AppDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData leadingIcon;
  final DateFormat format;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate; // kalau controller kosong, pakai ini
  final Locale? locale;        // contoh: const Locale('id','ID')
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DateTime?>? onChanged; // callback setelah pilih/clear

  // ⬇️ constructor TIDAK const
  AppDateField({
    super.key,
    required this.controller,
    this.label = 'Date',
    this.hintText,
    this.leadingIcon = Icons.date_range,
    DateFormat? format,
    DateTime? firstDate,
    DateTime? lastDate,
    this.initialDate,
    this.locale,
    this.enabled = true,
    this.validator,
    this.onChanged,
  })  : format = format ?? DateFormat('yyyy-MM-dd'),
        firstDate = firstDate ?? DateTime(2000, 1, 1),
        lastDate  = lastDate  ?? DateTime(2100, 12, 31);

  DateTime _parseCurrentOr(DateTime fallback) {
    final txt = controller.text.trim();
    if (txt.isEmpty) return fallback;
    // Coba parse sesuai format tampilan dulu, lalu fallback ISO8601
    try {
      return format.parseStrict(txt);
    } catch (_) {
      try {
        return DateTime.parse(txt);
      } catch (_) {
        return fallback;
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final init = initialDate ?? _parseCurrentOr(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(firstDate) || init.isAfter(lastDate) ? firstDate : init,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih tanggal',
      // locale: locale, // aktifkan kalau perlu
    );

    if (picked != null) {
      controller.text = format.format(picked);
      onChanged?.call(picked);
    }
  }

  void _clear() {
    controller.clear();
    onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      validator: validator,
      onTap: enabled ? () => _pickDate(context) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? format.pattern, // tampilkan pola sebagai hint
        prefixIcon: Icon(leadingIcon),
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pilih tanggal',
              icon: const Icon(Icons.calendar_today),
              onPressed: enabled ? () => _pickDate(context) : null,
            ),
          ],
        ),
      ),
    );
  }
}
