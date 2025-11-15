// =============================
// lib/features/production/broker/widgets/inputs_group_popover.dart
// Updated: Delete All (TEMP) per grup + realtime via Provider
//          Header chip "TEMP PARTIAL" bila isi temp adalah partial (berdasar data)
//          Label tombol hapus dinamis (TEMP / TEMP Partial) + aktif hanya saat ada TEMP
// =============================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/broker_production_input_view_model.dart';

/// Cek apakah bucket TEMP untuk labelCode berisi item partial.
/// (Sumber kebenaran: ada nomor partial di item, mis. noBBPartial/noGilinganPartial/… non-empty)
bool _hasPartialTempForLabel(BrokerProductionInputViewModel vm, String labelCode) {
  final b = vm.getTemporaryDataForLabel(labelCode.trim());
  if (b == null || b.isEmpty) return false;

  final hasBbPart       = b.bbItems.any((e) => (e.noBBPartial ?? '').trim().isNotEmpty);
  final hasGilinganPart = b.gilinganItems.any((e) => (e.noGilinganPartial ?? '').trim().isNotEmpty);
  final hasMixerPart    = b.mixerItems.any((e) => (e.noMixerPartial ?? '').trim().isNotEmpty);
  final hasRejectPart   = b.rejectItems.any((e) => (e.noRejectPartial ?? '').trim().isNotEmpty);

  return hasBbPart || hasGilinganPart || hasMixerPart || hasRejectPart;
}

/// Popover tooltip di sebelah KIRI anchor tile.
class InputsGroupTooltip extends StatelessWidget {
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

  /// Tombol Hapus Semua (TEMP) - kiri footer
  final VoidCallback? onDeleteAllTemp;
  final bool deleteAllTempDisabled;
  final String deleteAllTempLabel;

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
    this.onDeleteAllTemp,
    this.deleteAllTempDisabled = false,
    this.deleteAllTempLabel = 'Hapus Semua (TEMP)',
  });

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);
    final double clampedMaxH = maxHeight.clamp(180.0, 520.0).toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, maxWidth: width, maxHeight: clampedMaxH),
      child: Material(
        color: Colors.transparent,
        child: Material(
          color: Colors.white,
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [headerColor.withOpacity(0.65), headerColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),

                      // === Title + subtitle + (optional) chip TEMP / TEMP PARTIAL ===
                      Expanded(
                        child: Builder(
                          builder: (_) {
                            final vm = context.read<BrokerProductionInputViewModel>();
                            final hasTempForThis = vm.hasTemporaryDataForLabel(title);
                            final hasPartialTemp = _hasPartialTempForLabel(vm, title);
                            final showTempChip = hasTempForThis;
                            final chipText = hasPartialTemp ? 'TEMP PARTIAL' : 'TEMP';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title.isEmpty ? '-' : title,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: Colors.white.withOpacity(0.35)),
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
                                if ((subtitle ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                divider,

                // Table header (opsional)
                if (tableHeaders != null && tableHeaders!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: tableHeaders!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final header = entry.value;

                        // Kolom aksi terakhir lebar tetap
                        if (index == tableHeaders!.length - 1) {
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

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < tableHeaders!.length - 1 ? 8 : 0),
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
                      }).toList(),
                    ),
                  ),
                ],

                // Body: realtime via Consumer
                Flexible(
                  child: Consumer<BrokerProductionInputViewModel>(
                    builder: (context, vm, _) {
                      final children = childrenBuilder();

                      if (children.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Tidak ada data',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        itemBuilder: (_, i) => children[i],
                        separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                        itemCount: children.length,
                      );
                    },
                  ),
                ),

                // Footer: Hapus Semua TEMP (kiri) + actions custom (kanan)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      if (onDeleteAllTemp != null)
                        TextButton.icon(
                          onPressed: deleteAllTempDisabled ? null : onDeleteAllTemp,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(deleteAllTempLabel),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      const Spacer(),
                      ...actions,
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
  final VoidCallback? onDelete;
  final Color? deleteColor;
  final bool showDelete;
  final bool isHighlighted;
  final bool isDisabled;

  const TooltipTableRow({
    super.key,
    required this.columns,
    this.onDelete,
    this.deleteColor,
    this.showDelete = true,
    this.isHighlighted = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.yellow.shade50 : Colors.transparent,
      ),
      child: Row(
        children: [
          ...columns.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < columns.length - 1 ? 8 : 0),
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

          // Kolom aksi
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
                          color: deleteColor ?? Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isDisabled ? Icons.lock_outline : Icons.delete_outline,
                        size: 16,
                        color: deleteColor ?? Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              )
                  : const Text('-', style: TextStyle(color: Colors.grey)),
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
    this.popoverWidth = 400,
    this.gap = 16,
    this.onUpdate,
  });

  @override
  State<GroupTooltipAnchorTile> createState() => _GroupTooltipAnchorTileState();
}

class _GroupTooltipAnchorTileState extends State<GroupTooltipAnchorTile> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  void _show() {
    if (_entry != null) return;

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;

    final rb = context.findRenderObject() as RenderBox; // tile box
    final targetTopLeft = rb.localToGlobal(Offset.zero, ancestor: overlayBox);
    final tileSize = rb.size;

    final screenH = overlayBox.size.height;
    final padding = MediaQuery.of(context).padding;

    final double spaceBelow =
    (screenH - (targetTopLeft.dy + tileSize.height) - 12 - padding.bottom).toDouble();
    final double spaceAbove = (targetTopLeft.dy - 12 - padding.top).toDouble();

    const double minDesired = 260.0;
    final bool placeAbove = spaceBelow < minDesired && spaceAbove > spaceBelow;

    final double maxHeight = (placeAbove ? spaceAbove : spaceBelow).clamp(180.0, 520.0).toDouble();
    final double dy = placeAbove ? -(maxHeight - 8.0) : -8.0;

    // Baca state VM untuk tombol Hapus Semua (TEMP)
    final vm = context.read<BrokerProductionInputViewModel>();
    final hasTempForThis = vm.hasTemporaryDataForLabel(widget.title);
    final hasPartialTemp = _hasPartialTempForLabel(vm, widget.title);

    // Label tombol mengikuti isi bucket TEMP
    final delAllLabel = hasPartialTemp ? 'Hapus Semua (TEMP Partial)' : 'Hapus Semua (TEMP)';

    _entry = OverlayEntry(builder: (context) {
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

          // Popover di kiri tile
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(-(widget.popoverWidth + widget.gap), dy),
            child: InputsGroupTooltip(
              title: widget.title,
              subtitle: (widget.headerSubtitle ?? '').trim().isNotEmpty ? widget.headerSubtitle!.trim() : null,
              headerColor: widget.color,
              onClose: _hide,
              width: widget.popoverWidth,
              maxHeight: maxHeight,
              tableHeaders: widget.tableHeaders,
              childrenBuilder: widget.detailsBuilder,

              // Tombol Hapus Semua (TEMP) — aktif hanya jika ada TEMP
              onDeleteAllTemp: hasTempForThis ? () => _handleDeleteAllTemp(vm) : null,
              deleteAllTempDisabled: !hasTempForThis,
              deleteAllTempLabel: delAllLabel,

              // Tombol OK
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
    });

    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> _handleDeleteAllTemp(BrokerProductionInputViewModel vm) async {
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

          final hasTempForThis = vm.hasTemporaryDataForLabel(widget.title);

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            elevation: 0,
            // opsional: seluruh tile sedikit kuning saat ada TEMP
            color: hasTempForThis ? Colors.yellow.shade50 : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: hasTempForThis ? Colors.amber.shade200 : Colors.grey.shade200,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _show,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // === JUDUL DENGAN BG KUNING SAAT TEMP ===
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasTempForThis ? Colors.brown.shade800 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // jumlah baris (badge)
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
