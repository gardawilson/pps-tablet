// lib/core/widgets/card_container.dart

import 'package:flutter/material.dart';

/// Generic card container widget with consistent styling
///
/// A reusable card widget with customizable padding, border, and shadow.
/// Provides a clean, elevated container for content.
///
/// Example:
/// ```dart
/// CardContainer(
///   child: Text('Content here'),
/// )
/// ```
class CardContainer extends StatelessWidget {
  /// The widget to display inside the card
  final Widget child;

  /// Padding inside the card (default: 20 on all sides)
  final EdgeInsetsGeometry? padding;

  /// Border radius of the card (default: 3)
  final double borderRadius;

  /// Background color of the card (default: white)
  final Color? backgroundColor;

  /// Border color of the card (default: #DFE1E6)
  final Color? borderColor;

  /// Width of the border (default: 1)
  final double borderWidth;

  /// Whether to show shadow (default: true)
  final bool showShadow;

  /// Custom shadow configuration
  final List<BoxShadow>? customShadow;

  /// On tap callback for making the card interactive
  final VoidCallback? onTap;

  const CardContainer({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 3,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.showShadow = true,
    this.customShadow,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFDFE1E6),
          width: borderWidth,
        ),
        boxShadow: showShadow
            ? (customShadow ??
            const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ])
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}