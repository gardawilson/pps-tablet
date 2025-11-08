import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  // Behavior
  final bool enabled;
  final bool readOnly;
  final bool allowDecimal;     // izinkan angka desimal
  final bool allowNegative;    // izinkan angka negatif
  final String decimalSeparator; // '.', ','

  final int? maxLength;
  final TextInputAction? textInputAction;

  // UI
  final String? hintText;
  final Widget? suffixIcon;
  final String? suffixText;
  final String? prefixText;

  // Form
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const AppNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.decimalSeparator = '.',
    this.maxLength,
    this.textInputAction,
    this.hintText,
    this.suffixIcon,
    this.suffixText,
    this.prefixText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  }) : assert(decimalSeparator == '.' || decimalSeparator == ',', 'decimalSeparator must be "." or ","');

  // Build regex formatter sesuai opsi
  List<TextInputFormatter> _formatters() {
    // escape '.' untuk regex
    final sep = RegExp.escape(decimalSeparator);
    String pattern;
    if (allowDecimal && allowNegative) {
      // ^-?\d*(sep?\d*)?$
      pattern = r'^-?\d*(' + sep + r'?\d*)?$';
    } else if (allowDecimal && !allowNegative) {
      pattern = r'^\d*(' + sep + r'?\d*)?$';
    } else if (!allowDecimal && allowNegative) {
      pattern = r'^-?\d*$';
    } else {
      pattern = r'^\d*$';
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(pattern)),
    ];
  }

  TextInputType _keyboard() {
    if (allowDecimal) {
      // Gunakan decimal pad
      return const TextInputType.numberWithOptions(decimal: true, signed: true);
    }
    return TextInputType.number;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: _keyboard(),
      inputFormatters: _formatters(),
      maxLength: maxLength,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 16), // non-bold
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15),
        hintText: hintText,
        prefixIcon: Icon(icon, size: 22, color: enabled ? null : Theme.of(context).disabledColor),
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}
