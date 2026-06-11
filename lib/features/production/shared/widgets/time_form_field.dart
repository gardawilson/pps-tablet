  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  class TimeFormField extends StatelessWidget {
    final TextEditingController controller;
    final String label;
    final String hintText;
    final String? Function(String?)? validator;
    final VoidCallback onPick;
    final bool enabled;

    const TimeFormField({
      required this.controller,
      required this.label,
      required this.hintText,
      required this.onPick,
      this.validator,
      this.enabled = true,
    });

    @override
    Widget build(BuildContext context) {
      return TextFormField(
        controller: controller,
        readOnly: true,
        enabled: enabled,
        onTap: enabled ? onPick : null,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: const Icon(Icons.access_time, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
        ],
      );
    }
  }
