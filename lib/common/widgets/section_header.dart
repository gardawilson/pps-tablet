// lib/core/widgets/section_header.dart

import 'package:flutter/material.dart';

/// Section header widget with icon, title, and optional subtitle badge
///
/// A reusable header component for marking sections within a page or panel.
/// Includes an icon, title text, and optional subtitle badge.
///
/// Example:
/// ```dart
/// SectionHeader(
///   icon: Icons.edit_note_outlined,
///   title: 'Header Modifications',
///   subtitle: '3 changes',
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// The icon to display on the left
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional subtitle shown as a badge (e.g., count or status)
  final String? subtitle;

  /// Optional action widget on the right (e.g., button)
  final Widget? action;

  /// Size of the icon (default: 18)
  final double iconSize;

  /// Color of the icon (default: #42526E)
  final Color? iconColor;

  /// Font size of the title (default: 14)
  final double titleFontSize;

  /// Color of the title text (default: #172B4D)
  final Color? titleColor;

  /// Font size of the subtitle badge (default: 11)
  final double subtitleFontSize;

  /// Background color of the subtitle badge (default: #F4F5F7)
  final Color? subtitleBackgroundColor;

  /// Text color of the subtitle badge (default: #6B778C)
  final Color? subtitleTextColor;

  /// Border radius of the subtitle badge (default: 3)
  final double subtitleBorderRadius;

  /// Spacing between elements (default: 8)
  final double spacing;

  const SectionHeader({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 18,
    this.iconColor,
    this.titleFontSize = 14,
    this.titleColor,
    this.subtitleFontSize = 11,
    this.subtitleBackgroundColor,
    this.subtitleTextColor,
    this.subtitleBorderRadius = 3,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? const Color(0xFF42526E),
        ),

        SizedBox(width: spacing),

        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: titleColor ?? const Color(0xFF172B4D),
            letterSpacing: -0.1,
          ),
        ),

        // Subtitle badge (optional)
        if (subtitle != null) ...[
          SizedBox(width: spacing),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: subtitleBackgroundColor ?? const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(subtitleBorderRadius),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                color: subtitleTextColor ?? const Color(0xFF6B778C),
              ),
            ),
          ),
        ],

        // Action widget (optional)
        if (action != null) ...[
          const Spacer(),
          action!,
        ],
      ],
    );
  }
}