import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'table_column_spec.dart';

/// Keep the same enum so API matches your paged table.
enum TableWidthMode { content, fill, clamp }

class HorizontalTable<T> extends StatefulWidget {
  const HorizontalTable({
    super.key,
    required this.rows,
    required this.columns,
    this.rowHeight = 52,
    this.headerColor = const Color(0xFF1565C0),
    this.horizontalPadding = 16,
    this.widthMode = TableWidthMode.content,
    this.selectedPredicate,
    this.onRowTap,
    this.onRowLongPress,
    this.emptyBuilder,
  });

  final List<T> rows;
  final List<TableColumnSpec<T>> columns;
  final double rowHeight;
  final Color headerColor;
  final double horizontalPadding;
  final TableWidthMode widthMode;

  final bool Function(T row)? selectedPredicate;
  final void Function(T row)? onRowTap;
  final void Function(T row, Offset globalPosition)? onRowLongPress;

  /// Optional placeholder when rows.isEmpty
  final WidgetBuilder? emptyBuilder;

  @override
  State<HorizontalTable<T>> createState() => _HorizontalTableState<T>();
}

class _HorizontalTableState<T> extends State<HorizontalTable<T>> {
  final _headerHCtrl = ScrollController();
  final _bodyHCtrl = ScrollController();
  bool _syncing = false;

  // Sum of column widths, floored to avoid fractional pixel overflows.
  double get _contentWidth =>
      widget.columns.fold<double>(0, (sum, c) => sum + c.width).floorToDouble();

  double _effectiveWidth(BoxConstraints cons) {
    final desired = _contentWidth + (widget.horizontalPadding * 2);
    switch (widget.widthMode) {
      case TableWidthMode.content:
        return desired;
      case TableWidthMode.fill:
        return desired >= cons.maxWidth ? desired : cons.maxWidth;
      case TableWidthMode.clamp:
        return desired <= cons.maxWidth ? desired : cons.maxWidth;
    }
  }

  @override
  void initState() {
    super.initState();
    // Body => Header (utama)
    _bodyHCtrl.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_headerHCtrl.hasClients && _headerHCtrl.offset != _bodyHCtrl.offset) {
        _headerHCtrl.jumpTo(_bodyHCtrl.offset);
      }
      _syncing = false;
    });
    // Header => Body (opsional)
    _headerHCtrl.addListener(() {
      if (_syncing) return;
      _syncing = true;
      if (_bodyHCtrl.hasClients && _bodyHCtrl.offset != _headerHCtrl.offset) {
        _bodyHCtrl.jumpTo(_headerHCtrl.offset);
      }
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _headerHCtrl.dispose();
    _bodyHCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: Colors.white,
      letterSpacing: 0.5,
    );

    // Keep border width in one place
    const double kLeftBorderW = 4.0;

    return Column(
      children: [
        // ===== HEADER =====
        Material(
          color: widget.headerColor,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: LayoutBuilder(
              builder: (_, cons) {
                final width = _effectiveWidth(cons);
                return SingleChildScrollView(
                  controller: _headerHCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: width),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.horizontalPadding,
                        vertical: 14,
                      ),
                      // 🔒 Lock header row width to columns sum
                      child: SizedBox(
                        width: _contentWidth,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.columns.map((c) {
                            return SizedBox(
                              width: c.width,
                              child: Text(
                                c.title,
                                style: c.headerStyle ?? defaultHeaderStyle,
                                textAlign: c.headerAlign,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ===== BODY (simple ListView) =====
        Expanded(
          child: LayoutBuilder(
            builder: (_, cons) {
              // Make the *container* wide enough to include content + paddings + left border.
              final double containerWidth =
                  _contentWidth + (widget.horizontalPadding * 2) + kLeftBorderW;

              if (widget.rows.isEmpty) {
                return Center(
                  child: widget.emptyBuilder?.call(context) ??
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tidak ada data.'),
                      ),
                );
              }

              return Scrollbar(
                controller: _bodyHCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _bodyHCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: containerWidth),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: widget.rows.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, index) {
                        final item = widget.rows[index];
                        final selected =
                            widget.selectedPredicate?.call(item) ?? false;
                        final isEven = index % 2 == 0;
                        final bgColor = selected
                            ? Colors.blue.shade50
                            : (isEven ? Colors.white : Colors.grey.shade50);

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPressStart: (d) =>
                              widget.onRowLongPress?.call(item, d.globalPosition),
                          onSecondaryTapDown: (d) =>
                              widget.onRowLongPress?.call(item, d.globalPosition),
                          child: InkWell(
                            onTap: () => widget.onRowTap?.call(item),
                            child: AnimatedContainer(
                              height: widget.rowHeight,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border(
                                  left: BorderSide(
                                    color: selected
                                        ? Colors.blue
                                        : Colors.transparent,
                                    width: kLeftBorderW,
                                  ),
                                ),
                              ),
                              // 🔒 Lock + 🪚 clip the inner content
                              child: ClipRect(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.horizontalPadding,
                                  ),
                                  child: SizedBox(
                                    // Keep the row exactly at columns sum
                                    width: _contentWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: widget.columns.map((c) {
                                        return SizedBox(
                                          width: c.width,
                                          child: Align(
                                            alignment: _toAlignment(c.cellAlign),
                                            child: DefaultTextStyle(
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: selected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: selected
                                                    ? Colors.blue.shade900
                                                    : Colors.grey.shade800,
                                              ),
                                              child: c.cellBuilder(context, item),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Alignment _toAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      default:
        return Alignment.centerLeft;
    }
  }
}
