// lib/core/widgets/simple_divider.dart

import 'package:flutter/material.dart';

/// Simple horizontal or vertical divider widget
///
/// A clean, customizable divider line for separating content.
/// Can be used as horizontal (default) or vertical divider.
///
/// Example:
/// ```dart
/// SimpleDivider()
/// ```
class SimpleDivider extends StatelessWidget {
  /// Height of the divider for horizontal orientation
  /// Width of the divider for vertical orientation
  /// (default: 1)
  final double thickness;

  /// Color of the divider (default: #EBECF0)
  final Color? color;

  /// Whether the divider is vertical (default: false)
  final bool isVertical;

  /// Margin around the divider (optional)
  final EdgeInsetsGeometry? margin;

  /// Indent from the start (left for horizontal, top for vertical)
  final double indent;

  /// Indent from the end (right for horizontal, bottom for vertical)
  final double endIndent;

  const SimpleDivider({
    Key? key,
    this.thickness = 1,
    this.color,
    this.isVertical = false,
    this.margin,
    this.indent = 0,
    this.endIndent = 0,
  }) : super(key: key);

  /// Creates a horizontal divider
  const SimpleDivider.horizontal({
    Key? key,
    this.thickness = 1,
    this.color,
    this.margin,
    this.indent = 0,
    this.endIndent = 0,
  })  : isVertical = false,
        super(key: key);

  /// Creates a vertical divider
  const SimpleDivider.vertical({
    Key? key,
    this.thickness = 1,
    this.color,
    this.margin,
    this.indent = 0,
    this.endIndent = 0,
  })  : isVertical = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? const Color(0xFFEBECF0);

    if (isVertical) {
      return Container(
        margin: margin,
        child: Column(
          children: [
            if (indent > 0) SizedBox(height: indent),
            Expanded(
              child: Container(
                width: thickness,
                color: dividerColor,
              ),
            ),
            if (endIndent > 0) SizedBox(height: endIndent),
          ],
        ),
      );
    }

    return Container(
      margin: margin,
      child: Row(
        children: [
          if (indent > 0) SizedBox(width: indent),
          Expanded(
            child: Container(
              height: thickness,
              color: dividerColor,
            ),
          ),
          if (endIndent > 0) SizedBox(width: endIndent),
        ],
      ),
    );
  }
}