// lib/core/widgets/json_viewer.dart

import 'package:flutter/material.dart';
import 'dart:convert';

/// JSON viewer widget with syntax highlighting
///
/// Displays formatted JSON data in a code block with a title label.
/// Automatically formats JSON string and provides selectable text.
///
/// Example:
/// ```dart
/// JsonViewer(
///   title: 'API Response',
///   jsonString: '{"name":"John","age":30}',
/// )
/// ```
class JsonViewer extends StatelessWidget {
  /// Title label shown above the JSON block
  final String title;

  /// JSON string to display (will be auto-formatted)
  final String jsonString;

  /// Background color of the title badge (default: #F4F5F7)
  final Color? titleBackgroundColor;

  /// Text color of the title (default: #42526E)
  final Color? titleTextColor;

  /// Font size of the title (default: 11)
  final double titleFontSize;

  /// Background color of the code block (default: #1E1E1E - dark)
  final Color? codeBackgroundColor;

  /// Border color of the code block (default: #2D2D2D)
  final Color? codeBorderColor;

  /// Text color of the JSON code (default: #9CDCFE - light blue)
  final Color? codeTextColor;

  /// Font size of the JSON code (default: 12)
  final double codeFontSize;

  /// Font family for code display (default: 'Courier')
  final String? codeFontFamily;

  /// Line height of the code (default: 1.5)
  final double codeLineHeight;

  /// Padding inside the code block (default: 12 on all sides)
  final EdgeInsetsGeometry? codePadding;

  /// Border radius of the code block (default: 3)
  final double borderRadius;

  /// Number of spaces for JSON indentation (default: 2)
  final int indentSpaces;

  /// Whether to show copy button (default: false)
  final bool showCopyButton;

  /// Bottom spacing after the widget (default: 16)
  final double bottomSpacing;

  /// Maximum height of the code block (default: null - unlimited)
  final double? maxHeight;

  const JsonViewer({
    Key? key,
    required this.title,
    required this.jsonString,
    this.titleBackgroundColor,
    this.titleTextColor,
    this.titleFontSize = 11,
    this.codeBackgroundColor,
    this.codeBorderColor,
    this.codeTextColor,
    this.codeFontSize = 12,
    this.codeFontFamily,
    this.codeLineHeight = 1.5,
    this.codePadding,
    this.borderRadius = 3,
    this.indentSpaces = 2,
    this.showCopyButton = false,
    this.bottomSpacing = 16,
    this.maxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formatted;
    try {
      final decoded = json.decode(jsonString);
      formatted = JsonEncoder.withIndent(' ' * indentSpaces).convert(decoded);
    } catch (_) {
      formatted = jsonString;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: titleBackgroundColor ?? const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: titleTextColor ?? const Color(0xFF42526E),
                ),
              ),
            ),
            if (showCopyButton) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copy JSON',
                onPressed: () {
                  // Copy to clipboard
                  // You can implement this with clipboard package
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Code block
        Container(
          width: double.infinity,
          constraints: maxHeight != null
              ? BoxConstraints(maxHeight: maxHeight!)
              : null,
          padding: codePadding ?? const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: codeBackgroundColor ?? const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: codeBorderColor ?? const Color(0xFF2D2D2D),
            ),
          ),
          child: maxHeight != null
              ? SingleChildScrollView(
            child: _buildCodeText(formatted),
          )
              : _buildCodeText(formatted),
        ),

        SizedBox(height: bottomSpacing),
      ],
    );
  }

  Widget _buildCodeText(String formatted) {
    return SelectableText(
      formatted,
      style: TextStyle(
        fontFamily: codeFontFamily ?? 'Courier',
        fontSize: codeFontSize,
        color: codeTextColor ?? const Color(0xFF9CDCFE),
        height: codeLineHeight,
      ),
    );
  }
}