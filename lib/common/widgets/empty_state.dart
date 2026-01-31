// lib/core/widgets/empty_state.dart

import 'package:flutter/material.dart';

/// Atlassian-style empty state widget
///
/// Displays a centered empty state with an icon, title, and optional subtitle.
/// Follows Atlassian Design System guidelines.
///
/// Example:
/// ```dart
/// EmptyState(
///   icon: Icons.search,
///   title: 'No results found',
///   subtitle: 'Try adjusting your search terms',
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// The icon to display in the empty state
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional subtitle text for additional context
  final String? subtitle;

  /// Optional action widget (e.g., a button)
  final Widget? action;

  /// Size of the icon container (default: 80)
  final double iconSize;

  /// Background color of the icon container (default: Atlassian subtle gray)
  final Color? iconBackgroundColor;

  /// Color of the icon (default: Atlassian subtle text)
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 80,
    this.iconBackgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with circular background
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: Icon(
                icon,
                size: iconSize / 2,
                color: iconColor ?? const Color(0xFFA5ADBA),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF42526E),
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B778C),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action widget (optional)
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}