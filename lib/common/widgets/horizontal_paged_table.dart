import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'table_column_spec.dart';

/// Cara menghitung lebar table terhadap viewport.
enum TableWidthMode { content, fill, clamp }

class HorizontalPagedTable<T> extends StatefulWidget {
  const HorizontalPagedTable({
    super.key,
    required this.pagingController,
    required this.columns,
    this.rowHeight = 52,
    this.headerColor = const Color(0xFF1565C0),
    this.horizontalPadding = 16,
    this.widthMode = TableWidthMode.content,
    this.selectedPredicate,
    this.onRowTap,
    this.onRowLongPress,
    this.firstPageProgress,
    this.newPageProgress,
    this.firstPageError,
    this.newPageError,
    this.noItems,
  });

  final PagingController<int, T> pagingController;
  final List<TableColumnSpec<T>> columns;
  final double rowHeight;
  final Color headerColor;

  /// Padding kiri/kanan untuk header & baris.
  final double horizontalPadding;

  /// Mode lebar: content (natural), fill (>= viewport), clamp (<= viewport).
  final TableWidthMode widthMode;

  /// Kembalikan true untuk menandai row sebagai selected (highlight).
  final bool Function(T row)? selectedPredicate;

  final void Function(T row)? onRowTap;
  final void Function(T row, Offset globalPosition)? onRowLongPress;

  final WidgetBuilder? firstPageProgress;
  final WidgetBuilder? newPageProgress;
  final WidgetBuilder? firstPageError;
  final WidgetBuilder? newPageError;
  final WidgetBuilder? noItems;

  @override
  State<HorizontalPagedTable<T>> createState() => _HorizontalPagedTableState<T>();
}

class _HorizontalPagedTableState<T> extends State<HorizontalPagedTable<T>> {
  // Dua controller: header & body disinkronkan dua-arah.
  final _headerHCtrl = ScrollController();
  final _bodyHCtrl = ScrollController();
  bool _syncing = false;

  // Selalu gunakan jumlah kolom yang dibulatkan ke bawah untuk hindari drift fractional px.
  double get _contentWidth =>
      widget.columns.fold<double>(0, (sum, c) => sum + c.width).floorToDouble();

  double _effectiveWidth(BoxConstraints cons) {
    final desired = _contentWidth + (widget.horizontalPadding * 2);
    switch (widget.widthMode) {
      case TableWidthMode.content:
        return desired; // natural = konten
      case TableWidthMode.fill:
        return desired >= cons.maxWidth ? desired : cons.maxWidth; // penuhi layar minimal
      case TableWidthMode.clamp:
      // Hanya aman jika kolom bisa di-resize. Tetap pakai min(desired, viewport).
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
    // Header => Body (opsional: biar bisa drag dari header juga)
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

    // Simpan lebar border di satu tempat (sinkron dgn decoration row).
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
                      // 🔒 Kunci lebar header ke jumlah kolom
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

        // ===== BODY (v5: PagingListener => state + fetchNextPage) =====
        Expanded(
          child: LayoutBuilder(
            builder: (_, cons) {
              // Pastikan kontainer horizontal cukup lebar utk konten + padding + border.
              final containerWidth =
                  _contentWidth + (widget.horizontalPadding * 2) + kLeftBorderW;

              return Scrollbar(
                controller: _bodyHCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _bodyHCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    // ⬅️ gunakan containerWidth agar ListView memberi lebar row yang cukup
                    constraints: BoxConstraints.tightFor(width: containerWidth),
                    child: PagingListener<int, T>(
                      controller: widget.pagingController,
                      builder: (context, state, fetchNextPage) {
                        return RefreshIndicator(
                          onRefresh: () async => widget.pagingController.refresh(),
                          child: PagedListView<int, T>(
                            state: state,
                            fetchNextPage: fetchNextPage,
                            padding: EdgeInsets.zero,
                            builderDelegate: PagedChildBuilderDelegate<T>(
                              itemBuilder: (context, item, index) {
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
                                          bottom: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      // 🔒 + ✂️ kunci & clip isi row
                                      child: ClipRect(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: widget.horizontalPadding,
                                          ),
                                          child: SizedBox(
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
                              firstPageProgressIndicatorBuilder:
                              widget.firstPageProgress ??
                                      (_) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              newPageProgressIndicatorBuilder:
                              widget.newPageProgress ??
                                      (_) => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                              firstPageErrorIndicatorBuilder:
                              widget.firstPageError ??
                                      (_) => Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text('Terjadi kesalahan memuat data.'),
                                    ),
                                  ),
                              newPageErrorIndicatorBuilder:
                              widget.newPageError ??
                                      (_) => const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child:
                                    Center(child: Text('Gagal memuat halaman berikutnya')),
                                  ),
                              noItemsFoundIndicatorBuilder:
                              widget.noItems ??
                                      (_) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text('Tidak ada data.'),
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
