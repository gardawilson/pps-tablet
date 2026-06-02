// lib/features/production/shared/widgets/production_input_group_tile.dart
//
// Tile kartu untuk satu grup label input produksi.
// Klik → tampilkan detail dialog (sak chip atau list detail).
// Long-press → callback opsional (misal: temp card options).

import 'package:flutter/material.dart';
import 'production_inline_stat.dart';
import 'production_panel_decoration.dart';

// ── Data chip per sak ─────────────────────────────────────────────────────────

class ProductionSakChip {
  final String label;
  final double? berat;
  final bool isTemp;
  final bool isPartial;
  final VoidCallback? onDelete;

  const ProductionSakChip({
    required this.label,
    this.berat,
    this.isTemp = false,
    this.isPartial = false,
    this.onDelete,
  });
}

// ── Input group tile ──────────────────────────────────────────────────────────

class ProductionInputGroupTile extends StatelessWidget {
  final String title;
  final String? headerSubtitle;
  final List<(IconData, String)> tileMetrics;
  final Color color;
  final bool isTemp;
  final bool expandable;
  final bool isPartialGroup;
  final String? partialReference;
  final VoidCallback? onLongPress;

  /// Jika diisi → dialog chip sak.
  final List<ProductionSakChip> Function()? chipItemsBuilder;

  /// Jika diisi → dialog list detail biasa.
  final List<Widget> Function()? detailsBuilder;

  const ProductionInputGroupTile({
    super.key,
    required this.title,
    required this.color,
    this.headerSubtitle,
    this.tileMetrics = const [],
    this.isTemp = false,
    this.expandable = true,
    this.isPartialGroup = false,
    this.partialReference,
    this.onLongPress,
    this.chipItemsBuilder,
    this.detailsBuilder,
  });

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isTemp
                        ? Colors.brown.shade800
                        : const Color(0xFF1A1D23),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPartialGroup) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'P',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if ((headerSubtitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              headerSubtitle!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
          if (tileMetrics.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: tileMetrics
                  .map((m) => ProductionMiniMetric(icon: m.$1, text: m.$2))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isTemp ? Colors.yellow.shade50 : Colors.white;
    final borderColor = isTemp ? Colors.amber.shade200 : kProductionBorder;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (chipItemsBuilder != null) {
            showDialog<void>(
              context: context,
              builder: (_) => ProductionSakChipDetailDialog(
                title: title,
                subtitle: headerSubtitle ?? '-',
                metrics: tileMetrics,
                chips: chipItemsBuilder!(),
              ),
            );
          } else if (detailsBuilder != null) {
            showDialog<void>(
              context: context,
              builder: (_) => ProductionInputGroupDetailDialog(
                title: title,
                subtitle: headerSubtitle ?? '-',
                metrics: tileMetrics,
                details: detailsBuilder!(),
              ),
            );
          }
        },
        onLongPress: onLongPress,
        child: _buildHeader(),
      ),
    );
  }
}

// ── Sak chip detail dialog ────────────────────────────────────────────────────

class ProductionSakChipDetailDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(IconData, String)> metrics;
  final List<ProductionSakChip> chips;

  const ProductionSakChipDetailDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.chips,
  });

  static String _fmt(double? v) {
    if (v == null) return '-';
    final s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle.isNotEmpty ? subtitle : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Chip grid
            Flexible(
              child: chips.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1.5,
                            ),
                        itemCount: chips.length,
                        itemBuilder: (_, i) {
                          final chip = chips[i];
                          final bgColor = chip.isTemp
                              ? Colors.amber.shade50
                              : chip.isPartial
                              ? Colors.deepOrange.shade50
                              : const Color(0xFFF0F7FF);
                          final borderColor = chip.isTemp
                              ? Colors.amber.shade300
                              : chip.isPartial
                              ? Colors.deepOrange.shade200
                              : const Color(0xFFBFDBFE);
                          final textColor = chip.isPartial
                              ? Colors.deepOrange.shade800
                              : const Color(0xFF1D4ED8);
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          chip.label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_fmt(chip.berat)} kg',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (chip.isPartial)
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              if (chip.onDelete != null)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: chip.onDelete,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── List detail dialog ────────────────────────────────────────────────────────

class ProductionInputGroupDetailDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(IconData, String)> metrics;
  final List<Widget> details;

  const ProductionInputGroupDetailDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle.isNotEmpty ? subtitle : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: details.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemBuilder: (_, i) => details[i],
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Colors.grey.shade200,
                      ),
                      itemCount: details.length,
                    ),
            ),
            const Divider(height: 1, color: kProductionBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kProductionBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
