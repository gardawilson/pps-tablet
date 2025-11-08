// =============================
// lib/features/production/broker/widgets/inputs_group_popover.dart
// Updated: add optional `headerTitle` so tooltip header can show JENIS
// =============================

import 'package:flutter/material.dart';

/// A tooltip-like popover that appears to the LEFT of an anchor tile.
/// Use with [GroupTooltipAnchorTile] which manages the overlay.
class InputsGroupTooltip extends StatelessWidget {
  /// Header title (nomor label/partial)
  final String title;
  /// Optional subtitle (nama jenis)
  final String? subtitle;
  /// Section tint color (blue/cyan/etc)
  final Color headerColor;
  /// Rows of details
  final List<Widget> children;
  final VoidCallback onClose;
  /// Optional action buttons at the bottom
  final List<Widget> actions;
  /// Fixed width for easier anchoring math; keep <= 380 for narrow layouts.
  final double width;
  /// Max height computed by the anchor tile (space above/below). We only clamp here.
  final double maxHeight;

  const InputsGroupTooltip({
    super.key,
    required this.title,
    this.subtitle,
    required this.headerColor,
    required this.children,
    required this.onClose,
    required this.maxHeight,
    this.actions = const [],
    this.width = 340,
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
                // Header band
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? '-' : title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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

                // List of children
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemBuilder: (_, i) => children[i],
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: children.length,
                  ),
                ),

                if (actions.isNotEmpty) ...[
                  divider,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        const Spacer(),
                        ...actions,
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile that acts as an anchor and opens [InputsGroupTooltip] on tap.
class GroupTooltipAnchorTile extends StatefulWidget {
  /// Text yang tampil di tile (biasanya nomor label/partial).
  final String title;
  /// NEW: subtitle di header tooltip (mis. Nama Jenis). Jika null/empty, tidak ditampilkan.
  final String? headerSubtitle;
  /// header tint color
  final Color color;
  /// children rows for tooltip
  final List<Widget> details;
  /// default 340, must match InputsGroupTooltip.width
  final double popoverWidth;
  /// horizontal gap between tile and tooltip
  final double gap;

  const GroupTooltipAnchorTile({
    super.key,
    required this.title,
    required this.color,
    required this.details,
    this.headerSubtitle,
    this.popoverWidth = 340,
    this.gap = 16,
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
    final padding = MediaQuery.of(context).padding; // SafeArea

    final double spaceBelow = (screenH - (targetTopLeft.dy + tileSize.height) - 12 - padding.bottom).toDouble();
    final double spaceAbove = (targetTopLeft.dy - 12 - padding.top).toDouble();

    const double minDesired = 260.0;
    final bool placeAbove = spaceBelow < minDesired && spaceAbove > spaceBelow;

    // Compute max height available in the chosen direction
    final double maxHeight = (placeAbove ? spaceAbove : spaceBelow)
        .clamp(180.0, 520.0)
        .toDouble();

    // Vertical offset relative to tile top-left
    final double dy = placeAbove ? -(maxHeight - 8.0) : -8.0;

    _entry = OverlayEntry(builder: (context) {
      return Stack(
        children: [
          // Barrier to dismiss on outside tap
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hide,
              child: const SizedBox.expand(),
            ),
          ),

          // Anchored follower positioned to the LEFT of the tile
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(-(widget.popoverWidth + widget.gap), dy),
            child: InputsGroupTooltip(
              title: widget.title,                    // nomor label/partial
              subtitle: (widget.headerSubtitle ?? '').trim().isEmpty
                  ? null
                  : widget.headerSubtitle!.trim(),    // jenis (subjudul)
              headerColor: widget.color,
              onClose: _hide,
              width: widget.popoverWidth,
              maxHeight: maxHeight,
              children: widget.details,
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

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _show,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// =============================
// PATCHES in screen (BrokerInputsScreen)
// How to pass `headerTitle` (Nama Jenis) into GroupTooltipAnchorTile
// =============================
/*
Contoh pemakaian pada setiap section saat membuat tile:

return GroupTooltipAnchorTile(
  title: entry.key,                       // tetap nomor label / partial
  headerTitle: (() {                      // NEW: judul tooltip = namaJenis
    final first = entry.value.isNotEmpty ? entry.value.first : null;
    if (first == null) return '-';
    // Ambil namaJenis sesuai tipe item
    if (first is BbItem) return first.namaJenis ?? '-';
    if (first is BrokerItem) return first.namaJenis ?? '-';
    if (first is WashingItem) return first.namaJenis ?? '-';
    if (first is CrusherItem) return first.namaJenis ?? '-';
    if (first is GilinganItem) return first.namaJenis ?? '-';
    if (first is MixerItem) return first.namaJenis ?? '-';
    if (first is RejectItem) return first.namaJenis ?? '-';
    return '-';
  })(),
  color: Colors.green,
  details: details,
);
*/

// Bila ingin helper generik (opsional), tambahkan di screen:
/*
String jenisHeaderOf(dynamic item) {
  try {
    if (item == null) return '-';
    final v = (item as dynamic).namaJenis;
    if (v is String && v.trim().isNotEmpty) return v;
    return '-';
  } catch (_) {
    return '-';
  }
}

// lalu pakai:
headerTitle: jenisHeaderOf(entry.value.isNotEmpty ? entry.value.first : null),
*/
