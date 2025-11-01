// common/widgets/table_column_spec.dart
import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  const TableColumnSpec({
    required this.title,
    required this.width,
    required this.cellBuilder,
    this.headerAlign = TextAlign.left,
    this.cellAlign = TextAlign.left,
    this.headerStyle,
    this.maxLines,
    this.ellipsis = false,
  });

  final String title;
  final double width;
  final Widget Function(BuildContext context, T row) cellBuilder;

  final TextAlign headerAlign;
  final TextAlign cellAlign;
  final TextStyle? headerStyle;

  final int? maxLines;
  final bool ellipsis;
}
