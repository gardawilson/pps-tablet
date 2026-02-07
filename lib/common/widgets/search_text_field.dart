import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF172B4D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B778C),
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFA5ADBA)),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFFDFE1E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  size: 18,
                  color: Color(0xFF6B778C),
                ),
                onPressed: () {
                  controller.clear();
                  if (onChanged != null) onChanged!('');
                },
              )
            : null,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
