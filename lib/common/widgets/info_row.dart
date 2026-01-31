// lib/core/widgets/info_row.dart

import 'package:flutter/material.dart';

/// Generic information row widget with icon, label, and value
///
/// Displays a row with an icon on the left and a label-value pair on the right.
/// Commonly used in detail panels, forms, and information displays.
///
/// Example:
/// ```dart
/// InfoRow(
///   icon: Icons.person,
///   label: 'User',
///   value: 'John Doe',
/// )
/// ```
class InfoRow extends StatelessWidget {
  /// The icon to display on the left
  final IconData icon;

  /// The label text (smaller, above the value)
  final String label;

  /// The value text (larger, below the label)
  final String value;

  /// Size of the icon (default: 16)
  final double iconSize;

  /// Color of the icon (default: #6B778C)
  final Color? iconColor;

  /// Spacing between icon and text (default: 10)
  final double spacing;

  /// Color of the label text (default: #6B778C)
  final Color? labelColor;

  /// Font size of the label (default: 11)
  final double labelFontSize;

  /// Color of the value text (default: #172B4D)
  final Color? valueColor;

  /// Font size of the value (default: 14)
  final double valueFontSize;

  /// Custom label style (overrides default styling)
  final TextStyle? labelStyle;

  /// Custom value style (overrides default styling)
  final TextStyle? valueStyle;

  /// Widget to display instead of icon (optional)
  final Widget? customIcon;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconSize = 16,
    this.iconColor,
    this.spacing = 10,
    this.labelColor,
    this.labelFontSize = 11,
    this.valueColor,
    this.valueFontSize = 14,
    this.labelStyle,
    this.valueStyle,
    this.customIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        customIcon ??
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? const Color(0xFF6B778C),
            ),

        SizedBox(width: spacing),

        // Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                label,
                style: labelStyle ??
                    TextStyle(
                      fontSize: labelFontSize,
                      color: labelColor ?? const Color(0xFF6B778C),
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 4),

              // Value
              Text(
                value,
                style: valueStyle ??
                    TextStyle(
                      fontSize: valueFontSize,
                      color: valueColor ?? const Color(0xFF172B4D),
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}