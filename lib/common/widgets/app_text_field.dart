import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  // Behavior
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;

  // UI
  final String? hintText;
  final Widget? suffixIcon;
  final String? suffixText;

  // Form
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.hintText,
    this.suffixIcon,
    this.suffixText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 16), // non-bold
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15),
        hintText: hintText,
        prefixIcon: Icon(icon, size: 22, color: enabled ? null : Theme.of(context).disabledColor),
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
