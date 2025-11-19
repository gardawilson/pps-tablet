// =============================
// lib/features/production/broker/widgets/inputs_group_popover.dart
// Updated: Delete All (TEMP) per grup + realtime via Provider
//          Header chip "TEMP PARTIAL" bila isi temp adalah partial (berdasar data)
//          Label tombol hapus dinamis (TEMP / TEMP Partial) + aktif hanya saat ada TEMP
//          Sinkron lebar kolom header & data via columnFlexes
//          Edit mode untuk multi-delete EXISTING (bukan TEMP) pakai checkbox
//          Permission: delete TEMP by isTemp, delete EXISTING by canDelete
// =============================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/loading_dialog.dart';
import '../view_model/broker_production_input_view_model.dart';

/// Cek apakah bucket TEMP untuk labelCode berisi item partial.
/// (Sumber kebenaran: ada nomor partial di item, mis. noBrokerPartial/noBBPartial/noGilinganPartial/… non-empty)
bool _hasPartialTempForLabel(
    BrokerProductionInputViewModel vm,
    String labelCode,
    ) {
  final b = vm.getTemporaryDataForLabel(labelCode.trim());
  if (b == null || b.isEmpty) return false;

  final hasBrokerPart =
  b.brokerItems.any((e) => (e.noBrokerPartial ?? '').trim().isNotEmpty);
  final hasBbPart =
  b.bbItems.any((e) => (e.noBBPartial ?? '').trim().isNotEmpty);
  final hasGilinganPart = b.gilinganItems
      .any((e) => (e.noGilinganPartial ?? '').trim().isNotEmpty);
  final hasMixerPart =
  b.mixerItems.any((e) => (e.noMixerPartial ?? '').trim().isNotEmpty);
  final hasRejectPart =
  b.rejectItems.any((e) => (e.noRejectPartial ?? '').trim().isNotEmpty);

  return hasBrokerPart ||
      hasBbPart ||
      hasGilinganPart ||
      hasMixerPart ||
      hasRejectPart;
}

/// Popover tooltip di sebelah KIRI anchor tile.
class InputsGroupTooltip extends StatefulWidget {
  /// Header title (nomor label/partial) -> juga dipakai sebagai labelCode
  final String title;

  /// Optional subtitle (nama jenis)
  final String? subtitle;

  /// Warna header
  final Color headerColor;

  /// Builder isi baris (realtime)
  final List<Widget> Function() childrenBuilder;
  final VoidCallback onClose;

  /// Actions custom di kanan footer
  final List<Widget> actions;

  /// Lebar & tinggi popover
  final double width;
  final double maxHeight;

  /// Header kolom opsional
  final List<String>? tableHeaders;

  /// Flex kolom data (tanpa kolom Action), digunakan untuk header & row
  final List<int>? columnFlexes;

  /// Tombol Hapus Semua (TEMP) - kiri footer
  final VoidCallback? onDeleteAllTemp;
  final bool deleteAllTempDisabled;
  final String deleteAllTempLabel;

  /// Permission delete existing rows
  final bool canDelete;

  const InputsGroupTooltip({
    super.key,
    required this.title,
    this.subtitle,
    required this.headerColor,
    required this.childrenBuilder,
    required this.onClose,
    required this.maxHeight,
    this.actions = const [],
    this.width = 340,
    this.tableHeaders,
    this.columnFlexes,
    this.onDeleteAllTemp,
    this.deleteAllTempDisabled = false,
    this.deleteAllTempLabel = 'Hapus Semua (TEMP)',
    this.canDelete = false,
  });

  @override
  State<InputsGroupTooltip> createState() => _InputsGroupTooltipState();
}

class _InputsGroupTooltipState extends State<InputsGroupTooltip> {
  // Mode edit / multi-delete untuk EXISTING (bukan temp)
  bool _selectionMode = false;

  // Index row yang terpilih
  final Set<int> _selectedIndices = <int>{};

  // Simpan callback onDelete untuk row existing per index
  final Map<int, VoidCallback> _rowDeleteCallbacks = <int, VoidCallback>{};

  void _enterSelectionMode() {
    if (!widget.canDelete) return; // safety guard
    setState(() {
      _selectionMode = true;
      _selectedIndices.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _toggleSelected(int index, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  void _confirmBulkDelete() async {
    if (_selectedIndices.isEmpty) return;

    final indices = _selectedIndices.toList()..sort();

    final callbacks = <VoidCallback>[];
    for (final i in indices) {
      final cb = _rowDeleteCallbacks[i];
      if (cb != null) {
        callbacks.add(cb);
      }
    }

    final count = callbacks.length;
    if (count == 0) return;

    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootCtx = rootNavigator.context;

    widget.onClose();

    final confirmed = await showDialog<bool>(
      context: rootCtx,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus $count item?'),
        content: Text(
          'Yakin ingin menghapus $count item yang sudah dipilih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    // ❌ TIDAK ADA loading dialog
    // ✅ Langsung eksekusi delete → skeleton otomatis muncul karena state loading
    for (final cb in callbacks) {
      cb();
    }

    // Snackbar setelah selesai
    await Future.delayed(const Duration(milliseconds: 300));
    if (rootCtx.mounted) {
      ScaffoldMessenger.of(rootCtx).showSnackBar(
        SnackBar(
          content: Text('✅ Berhasil menghapus $count item'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  /// Bungkus row supaya:
  /// - saat selectionMode, row existing (bukan TEMP) punya checkbox di kiri
  /// - seleksi existing hanya aktif kalau canDelete = true
  Widget _buildSelectableRow(Widget child, int index) {
    bool canSelect = false;

    // Semua TooltipTableRow existing (isTempRow == false) boleh dipilih
    // hanya jika permission canDelete = true
    if (widget.canDelete &&
        child is TooltipTableRow &&
        !child.isTempRow) {
      canSelect = true;

      // Kalau lagi selection mode, hide tombol delete single-row existing
      child = TooltipTableRow(
        columns: child.columns,
        columnFlexes: child.columnFlexes,
        onDelete: child.onDelete, // tetap dipass, dipakai bulk
        deleteColor: child.deleteColor,
        showDelete: !_selectionMode && child.showDelete,
        isHighlighted: child.isHighlighted,
        isDisabled: child.isDisabled,
        isTempRow: child.isTempRow,
      );
    }

    Widget content = child;

    if (_selectionMode && canSelect) {
      content = Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: _selectedIndices.contains(index),
              onChanged: (v) => _toggleSelected(index, v),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: content),
        ],
      );
    }

    return InkWell(
      onTap: () {
        if (_selectionMode && canSelect) {
          final now = _selectedIndices.contains(index);
          _toggleSelected(index, !now);
        }
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider =
    Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);
    final double clampedMaxH =
    widget.maxHeight.clamp(180.0, 520.0).toDouble();

    final bool canDeleteExisting = widget.canDelete;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.width,
        maxWidth: widget.width,
        maxHeight: clampedMaxH,
      ),
      child: Material(
        color: Colors.transparent,
        child: Material(
          color: Colors.white,
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: widget.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =======================================================
                // HEADER
                // =======================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.headerColor.withOpacity(0.65),
                        widget.headerColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final vm = context
                                .read<BrokerProductionInputViewModel>();
                            final hasTempForThis =
                            vm.hasTemporaryDataForLabel(widget.title);
                            final hasPartialTemp =
                            _hasPartialTempForLabel(vm, widget.title);
                            final showTempChip = hasTempForThis;
                            final chipText =
                            hasPartialTemp ? 'PENDING' : 'PENDING';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.title.isEmpty
                                            ? '-'
                                            : widget.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (showTempChip) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                          Colors.white.withOpacity(0.2),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                          border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.35),
                                          ),
                                        ),
                                        child: Text(
                                          chipText,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if ((widget.subtitle ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                      Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 🔧 TOMBOL EDIT / EXIT EDIT (disable kalau !canDeleteExisting)
                      IconButton(
                        tooltip: !canDeleteExisting
                            ? 'Tidak punya izin menghapus data existing'
                            : _selectionMode
                            ? 'Keluar mode hapus'
                            : 'Pilih data existing untuk dihapus',
                        icon: Icon(
                          _selectionMode
                              ? Icons.close_rounded
                              : Icons.edit,
                          color: canDeleteExisting
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                        onPressed: !canDeleteExisting
                            ? null
                            : () {
                          if (_selectionMode) {
                            _exitSelectionMode();
                          } else {
                            _enterSelectionMode();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                divider,

                // =======================================================
                // TABLE HEADER (opsional)
                // =======================================================
                if (widget.tableHeaders != null &&
                    widget.tableHeaders!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_selectionMode && canDeleteExisting)
                          const SizedBox(width: 32), // ruang checkbox
                        ...widget.tableHeaders!.asMap().entries.map(
                              (entry) {
                            final index = entry.key;
                            final header = entry.value;

                            // Kolom aksi terakhir lebar tetap
                            if (index ==
                                widget.tableHeaders!.length - 1) {
                              return SizedBox(
                                width: 60,
                                child: Text(
                                  header,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            // Flex sama dengan row data
                            final flex =
                            (widget.columnFlexes != null &&
                                index <
                                    widget
                                        .columnFlexes!.length &&
                                widget.columnFlexes![index] > 0)
                                ? widget.columnFlexes![index]
                                : 1;

                            return Expanded(
                              flex: flex,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index <
                                      widget.tableHeaders!.length - 1
                                      ? 8
                                      : 0,
                                ),
                                child: Text(
                                  header,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // =======================================================
                // BODY: realtime via Consumer
                // =======================================================
                Flexible(
                  child: Consumer<BrokerProductionInputViewModel>(
                    builder: (context, vm, _) {
                      final children = widget.childrenBuilder();

                      if (children.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Tidak ada data',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      // Kumpulkan callback delete hanya untuk row EXISTING (bukan temp)
                      _rowDeleteCallbacks.clear();
                      if (canDeleteExisting) {
                        for (var i = 0; i < children.length; i++) {
                          final child = children[i];
                          if (child is TooltipTableRow &&
                              child.onDelete != null &&
                              !child.isTempRow) {
                            _rowDeleteCallbacks[i] = child.onDelete!;
                          }
                        }
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        itemBuilder: (_, i) =>
                            _buildSelectableRow(children[i], i),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.shade200,
                        ),
                        itemCount: children.length,
                      );
                    },
                  ),
                ),

                // =======================================================
                // FOOTER
                // - normal: Hapus Semua TEMP + actions (Oke)
                // - selection mode: Batal + Hapus (n)  [hanya kalau canDelete = true]
                // =======================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: _selectionMode && canDeleteExisting
                        ? [
                      // Mode multi-delete existing
                      TextButton(
                        onPressed: _exitSelectionMode,
                        child: const Text('Batal'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _selectedIndices.isEmpty
                            ? null
                            : _confirmBulkDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Hapus (${_selectedIndices.length})',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ]
                        : [
                      // Mode normal
                      if (widget.onDeleteAllTemp != null)
                        TextButton.icon(
                          onPressed:
                          widget.deleteAllTempDisabled
                              ? null
                              : widget.onDeleteAllTemp,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                          ),
                          label: Text(widget.deleteAllTempLabel),
                          style: TextButton.styleFrom(
                            foregroundColor:
                            Colors.red.shade700,
                          ),
                        ),
                      const Spacer(),
                      ...widget.actions,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Table row sederhana dengan tombol delete di kolom aksi.
class TooltipTableRow extends StatelessWidget {
  final List<String> columns;

  /// Flex untuk tiap kolom data (BUKAN kolom action).
  /// Contoh: [3, 2] → kolom[0] 3 bagian, kolom[1] 2 bagian.
  final List<int>? columnFlexes;

  /// Callback hapus untuk row ini.
  final VoidCallback? onDelete;

  final Color? deleteColor;
  final bool showDelete;
  final bool isHighlighted;
  final bool isDisabled;

  /// Menandai bahwa row ini TEMP atau bukan.
  /// Multi-delete hanya untuk row existing (isTempRow == false).
  final bool isTempRow;

  const TooltipTableRow({
    super.key,
    required this.columns,
    this.columnFlexes,
    this.onDelete,
    this.deleteColor,
    this.showDelete = true,
    this.isHighlighted = false,
    this.isDisabled = false,
    this.isTempRow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.yellow.shade50 : Colors.transparent,
      ),
      child: Row(
        children: [
          // Kolom-kolom data
          ...columns.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;

            // flex default = 1 kalau tidak diset
            final flex = (columnFlexes != null &&
                index < columnFlexes!.length &&
                columnFlexes![index] > 0)
                ? columnFlexes![index]
                : 1;

            return Expanded(
              flex: flex,
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < columns.length - 1 ? 8 : 0,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),

          // Kolom aksi (fixed width)
          SizedBox(
            width: 60,
            child: Center(
              child: showDelete && onDelete != null
                  ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: deleteColor ?? Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                          deleteColor ?? Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isDisabled
                            ? Icons.lock_outline
                            : Icons.delete_outline,
                        size: 16,
                        color: deleteColor ??
                            Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              )
                  : const Text(
                '-',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile anchor yang membuka [InputsGroupTooltip] saat di-tap.
class GroupTooltipAnchorTile extends StatefulWidget {
  /// Biasanya nomor label/partial, dan **dipakai sebagai labelCode**.
  final String title;
  final String? headerSubtitle;
  final Color color;

  /// Builder konten (realtime)
  final List<Widget> Function() detailsBuilder;

  final List<String>? tableHeaders;

  /// Flex kolom data (dipakai header & row)
  final List<int>? columnFlexes;

  /// Permission delete existing rows (temp tetap boleh dihapus)
  final bool canDelete;

  final double popoverWidth;
  final double gap;
  final VoidCallback? onUpdate;

  const GroupTooltipAnchorTile({
    super.key,
    required this.title,
    required this.color,
    required this.detailsBuilder,
    this.headerSubtitle,
    this.tableHeaders,
    this.columnFlexes,
    this.canDelete = false,
    this.popoverWidth = 400,
    this.gap = 16,
    this.onUpdate,
  });

  @override
  State<GroupTooltipAnchorTile> createState() =>
      _GroupTooltipAnchorTileState();
}

class _GroupTooltipAnchorTileState extends State<GroupTooltipAnchorTile> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    if (_entry != null) return;

    final overlay = Overlay.of(context);
    final overlayBox =
    overlay.context.findRenderObject() as RenderBox;

    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final padding = media.padding;

    // --- posisi & ukuran tile (anchor) ---
    final rb = context.findRenderObject() as RenderBox;
    final targetTopLeft =
    rb.localToGlobal(Offset.zero, ancestor: overlayBox);
    final tileSize = rb.size;
    final tileCenterY = targetTopLeft.dy + tileSize.height / 2;

    // --- tinggi maksimal popover ---
    final double maxHeight =
    (screenH - padding.vertical - 32)
        .clamp(180.0, 520.0)
        .toDouble();

    // Batas aman atas & bawah layar (kasih margin 8px)
    final double topLimit = padding.top + 8;
    final double bottomLimit = screenH - padding.bottom - 8;

    // Hitung offset Y supaya popover tidak keluar layar
    double yOffset = 0.0;

    final double popoverTop = tileCenterY - maxHeight / 2;
    final double popoverBottom = tileCenterY + maxHeight / 2;

    if (popoverTop < topLimit) {
      // Terlalu ke atas → geser turun
      yOffset = topLimit - popoverTop;
    } else if (popoverBottom > bottomLimit) {
      // Terlalu ke bawah → geser naik
      yOffset = bottomLimit - popoverBottom;
    }

    // --- state VM untuk tombol Hapus TEMP ---
    final vm = context.read<BrokerProductionInputViewModel>();
    final hasTempForThis =
    vm.hasTemporaryDataForLabel(widget.title);
    final hasPartialTemp =
    _hasPartialTempForLabel(vm, widget.title);
    final delAllLabel = hasPartialTemp
        ? 'Hapus Semua (TEMP Partial)'
        : 'Hapus Semua (TEMP)';

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier untuk dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hide,
                child: const SizedBox.expand(),
              ),
            ),

            // POPUP: kiri tile, vertikal auto-clamp
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,

              // kiri-tengah tile ↔ kanan-tengah popover
              targetAnchor: Alignment.centerLeft,
              followerAnchor: Alignment.centerRight,

              // X: geser ke kiri sedikit; Y: disesuaikan supaya tidak kepotong
              offset: Offset(-widget.gap, yOffset),

              child: InputsGroupTooltip(
                title: widget.title,
                subtitle: (widget.headerSubtitle ?? '')
                    .trim()
                    .isNotEmpty
                    ? widget.headerSubtitle!.trim()
                    : null,
                headerColor: widget.color,
                onClose: _hide,
                width: widget.popoverWidth,
                maxHeight: maxHeight,
                tableHeaders: widget.tableHeaders,
                columnFlexes: widget.columnFlexes,
                canDelete: widget.canDelete,
                childrenBuilder: widget.detailsBuilder,
                onDeleteAllTemp: hasTempForThis
                    ? () => _handleDeleteAllTemp(vm)
                    : null,
                deleteAllTempDisabled: !hasTempForThis,
                deleteAllTempLabel: delAllLabel,
                actions: [
                  TextButton.icon(
                    onPressed: _hide,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Oke'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> _handleDeleteAllTemp(
      BrokerProductionInputViewModel vm) async {
    // langsung hapus semua TEMP untuk label (widget.title)
    final removed = vm.deleteAllTempForLabel(widget.title);

    // trigger refresh opsional dari parent
    widget.onUpdate?.call();

    // tutup popover
    _hide();

    // info ke user
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed > 0
              ? 'Berhasil menghapus $removed item TEMP.'
              : 'Tidak ada item TEMP untuk dihapus.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: Consumer<BrokerProductionInputViewModel>(
        builder: (context, vm, _) {
          final details = widget.detailsBuilder();
          if (details.isEmpty) return const SizedBox.shrink();

          final hasTempForThis =
          vm.hasTemporaryDataForLabel(widget.title);

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            elevation: 0,
            // opsional: seluruh tile sedikit kuning saat ada TEMP
            color: hasTempForThis
                ? Colors.yellow.shade50
                : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: hasTempForThis
                    ? Colors.amber.shade200
                    : Colors.grey.shade200,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _show,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // === JUDUL DENGAN BG KUNING SAAT TEMP ===
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasTempForThis
                                ? Colors.brown.shade800
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // jumlah baris (badge)
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${details.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
