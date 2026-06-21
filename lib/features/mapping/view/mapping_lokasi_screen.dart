import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/model/mapping_layout_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view/mapping_layout_editor_screen.dart';
import 'package:pps_tablet/features/mapping/view/widgets/label_dialog.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_label_view_model.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_lokasi_view_model.dart';

const Color _primary = Color(0xFF0D47A1);
const Color _aisleColor = Color(0xFFFFD600);
const Color _emptyColor = Color(0xFFF5F5F5);
const Color _labelColor = Color(0xFFE8F5E9);

// Cek apakah ada sel aisle (termasuk covered milik aisle) dalam rentang baris/kolom
bool _hasAisleInRange(
  List<List<GridCell>> grid,
  int r1,
  int r2,
  int c1,
  int c2,
) {
  for (int r = r1; r <= r2; r++) {
    for (int c = c1; c <= c2; c++) {
      if (r < 0 || c < 0 || r >= grid.length || c >= grid[0].length) continue;
      final cell = grid[r][c];
      if (cell.type == CellType.aisle) return true;
      if (cell.type == CellType.covered) {
        final origin = grid[cell.originRow!][cell.originCol!];
        if (origin.type == CellType.aisle) return true;
      }
    }
  }
  return false;
}

class MappingLokasiScreen extends StatelessWidget {
  final String blok;
  final String namaWarehouse;

  const MappingLokasiScreen({
    super.key,
    required this.blok,
    required this.namaWarehouse,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MappingLokasiViewModel(
        repository: MappingRepository(api: ApiClient()),
      )..loadLokasiByBlok(blok),
      child: _MappingLokasiView(blok: blok, namaWarehouse: namaWarehouse),
    );
  }
}

class _MappingLokasiView extends StatelessWidget {
  final String blok;
  final String namaWarehouse;

  const _MappingLokasiView({required this.blok, required this.namaWarehouse});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLokasiViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildContent(context, vm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final vm = context.read<MappingLokasiViewModel>();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MappingLayoutEditorScreen(
                blok: blok,
                namaWarehouse: namaWarehouse,
                lokasiList: vm.lokasiList,
              ),
            ),
          );
          vm.loadLokasiByBlok(blok);
        },
        icon: const Icon(Icons.edit_rounded, size: 16),
        label: const Text(
          'Edit Layout',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(BuildContext context, MappingLokasiViewModel vm) {
    if (vm.isLoading && vm.lokasiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error.isNotEmpty && vm.lokasiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(vm.error, textAlign: TextAlign.center),
        ),
      );
    }

    if (vm.lokasiList.isEmpty) {
      return const Center(child: Text('Data lokasi kosong'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: vm.hasLayout
              ? _buildLayoutView(context, vm)
              : _buildCardGrid(context, vm),
        ),
        if (vm.hasLayout) _buildLegend(),
      ],
    );
  }

  // ── Layout grid (read-only) ───────────────────────────────────────────────

  static const double _slotW = 67.0;
  static const double _slotH = 59.0;
  static const double _gutterW = 28.0;
  static const double _headerH = 20.0;

  Widget _buildLayoutView(BuildContext context, MappingLokasiViewModel vm) {
    final gridW = vm.layoutCols * _slotW;
    final gridH = vm.layoutRows * _slotH;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row number gutter
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: _headerH + 4),
                for (int r = 0; r < vm.layoutRows; r++)
                  SizedBox(
                    width: _gutterW,
                    height: _slotH,
                    child: Center(
                      child: Text(
                        '${r + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column numbers header
                SizedBox(
                  height: _headerH,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int c = 0; c < vm.layoutCols; c++)
                        SizedBox(
                          width: _slotW,
                          child: Center(
                            child: Text(
                              '${c + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: gridW,
                  height: gridH,
                  child: Stack(
                    children: [
                      for (int r = 0; r < vm.layoutRows; r++)
                        for (int c = 0; c < vm.layoutCols; c++)
                          if (vm.layoutGrid[r][c].type != CellType.covered)
                            Positioned(
                              left: c * _slotW,
                              top: r * _slotH,
                              child: _buildReadOnlyCell(
                                context,
                                vm,
                                vm.layoutGrid[r][c],
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyCell(
    BuildContext context,
    MappingLokasiViewModel vm,
    GridCell cell,
  ) {
    final isEmpty = cell.type == CellType.empty;
    final isAisle = cell.type == CellType.aisle;
    final isLokasi = cell.type == CellType.lokasi;
    final isLabel = cell.type == CellType.label;

    // Adjacency check untuk aisle — sisi yang bersentuhan dengan aisle lain akan menyatu
    final bool mergeTop, mergeBottom, mergeLeft, mergeRight;
    if (isAisle) {
      final r = cell.row;
      final c = cell.col;
      final rs = cell.rowSpan;
      final cs = cell.colSpan;
      final g = vm.layoutGrid;
      final rows = vm.layoutRows;
      final cols = vm.layoutCols;
      mergeTop = r > 0 && _hasAisleInRange(g, r - 1, r - 1, c, c + cs - 1);
      mergeBottom =
          r + rs < rows && _hasAisleInRange(g, r + rs, r + rs, c, c + cs - 1);
      mergeLeft = c > 0 && _hasAisleInRange(g, r, r + rs - 1, c - 1, c - 1);
      mergeRight =
          c + cs < cols && _hasAisleInRange(g, r, r + rs - 1, c + cs, c + cs);
    } else {
      mergeTop = mergeBottom = mergeLeft = mergeRight = false;
    }

    // Ukuran: aisle yang merge diperluas ke sisi yang menyatu (hilangkan gap 1.5px)
    final double width = isEmpty
        ? _slotW
        : isAisle
        ? cell.colSpan * _slotW -
              3 +
              (mergeLeft ? 1.5 : 0) +
              (mergeRight ? 1.5 : 0)
        : cell.colSpan * _slotW - 3;
    final double height = isEmpty
        ? _slotH
        : isAisle
        ? cell.rowSpan * _slotH -
              3 +
              (mergeTop ? 1.5 : 0) +
              (mergeBottom ? 1.5 : 0)
        : cell.rowSpan * _slotH - 3;

    final EdgeInsets margin = isEmpty
        ? EdgeInsets.zero
        : isAisle
        ? EdgeInsets.only(
            left: mergeLeft ? 0 : 1.5,
            top: mergeTop ? 0 : 1.5,
            right: mergeRight ? 0 : 1.5,
            bottom: mergeBottom ? 0 : 1.5,
          )
        : const EdgeInsets.all(1.5);

    Color bgColor = _emptyColor;
    if (isAisle) bgColor = _aisleColor;
    if (isLokasi) bgColor = Colors.white;
    if (isLabel) bgColor = _labelColor;

    // Border & radius: hilangkan di sisi yang menyatu
    final BorderRadius borderRadius = isAisle
        ? BorderRadius.only(
            topLeft: Radius.circular(mergeTop || mergeLeft ? 0 : 6),
            topRight: Radius.circular(mergeTop || mergeRight ? 0 : 6),
            bottomLeft: Radius.circular(mergeBottom || mergeLeft ? 0 : 6),
            bottomRight: Radius.circular(mergeBottom || mergeRight ? 0 : 6),
          )
        : BorderRadius.circular(isEmpty ? 0 : 6);

    final BorderSide aisleSide = BorderSide(
      color: Colors.orange.shade700.withValues(alpha: 0.5),
    );
    final Border border = isLokasi
        ? Border.all(color: _primary.withValues(alpha: 0.5), width: 1.5)
        : isAisle
        ? Border(
            top: mergeTop ? BorderSide.none : aisleSide,
            bottom: mergeBottom ? BorderSide.none : aisleSide,
            left: mergeLeft ? BorderSide.none : aisleSide,
            right: mergeRight ? BorderSide.none : aisleSide,
          )
        : isLabel
        ? Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.5))
        : Border.all(color: Colors.grey.shade200, width: 0.5);

    return GestureDetector(
      onTap: isLokasi
          ? () {
              final lokasi = vm.lokasiList
                  .where((l) => l.idLokasi == cell.idLokasi)
                  .firstOrNull;
              if (lokasi != null) _showLabelDialog(context, lokasi);
            }
          : null,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: border,
          boxShadow: isLokasi
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: isAisle
            ? Center(
                child: Icon(
                  Icons.horizontal_rule_rounded,
                  size: 16,
                  color: Colors.orange.shade800.withValues(alpha: 0.6),
                ),
              )
            : isLabel
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cell.labelText ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                      height: 1.2,
                    ),
                  ),
                ),
              )
            : isLokasi
            ? Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cell.lokasiLabel ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cell.lokasiDescription?.isNotEmpty == true
                          ? cell.lokasiDescription!
                          : '-',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildTotalLabelBadge(vm, cell),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTotalLabelBadge(MappingLokasiViewModel vm, GridCell cell) {
    final lokasi = vm.lokasiList
        .where((l) => l.idLokasi == cell.idLokasi)
        .firstOrNull;
    if (lokasi == null) return const SizedBox.shrink();

    final hasLabel = lokasi.totalLabel > 0;

    String? uomText;
    bool hasUom = false;
    final uom = lokasi.namaUOM.toUpperCase();
    if (uom == 'KG' || lokasi.totalBerat > 0) {
      hasUom = lokasi.totalBerat > 0;
      uomText = '${_formatNum(lokasi.totalBerat)} kg';
    } else if (uom == 'PCS' || lokasi.totalQty > 0) {
      hasUom = lokasi.totalQty > 0;
      uomText = '${lokasi.totalQty} pcs';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: hasLabel
                ? _primary.withValues(alpha: 0.10)
                : Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${lokasi.totalLabel} label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasLabel ? _primary : Colors.grey,
            ),
          ),
        ),
        if (uomText != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: hasUom
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uomText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasUom ? const Color(0xFF2E7D32) : Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockBadge(MappingLokasi item) {
    final hasLabel = item.totalLabel > 0;

    final uom = item.namaUOM.toUpperCase();
    String? uomText;
    bool hasUom = false;
    if (uom == 'KG' || item.totalBerat > 0) {
      hasUom = item.totalBerat > 0;
      uomText = '${_formatNum(item.totalBerat)} kg';
    } else if (uom == 'PCS' || item.totalQty > 0) {
      hasUom = item.totalQty > 0;
      uomText = '${item.totalQty} pcs';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: hasLabel
                ? _primary.withValues(alpha: 0.10)
                : Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${item.totalLabel} label',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: hasLabel ? _primary : Colors.grey,
            ),
          ),
        ),
        if (uomText != null) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasUom
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uomText,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: hasUom ? const Color(0xFF2E7D32) : Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatNum(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  Widget _buildLegend() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.white, _primary, 'Lokasi', border: true),
          const SizedBox(width: 16),
          _legendItem(_aisleColor, Colors.orange.shade800, 'Jalan / Aisle'),
          const SizedBox(width: 16),
          _legendItem(_labelColor, const Color(0xFF1B5E20), 'Label'),
          const SizedBox(width: 16),
          _legendItem(_emptyColor, Colors.grey, 'Kosong'),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color fg, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: border
                ? Border.all(color: _primary.withValues(alpha: 0.4))
                : Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // ── Fallback card grid (belum ada layout) ─────────────────────────────────

  Widget _buildCardGrid(BuildContext context, MappingLokasiViewModel vm) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFFF8E1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text(
                'Layout belum dibuat. Tekan "Edit Layout" untuk membuat formasi.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: vm.lokasiList
                  .map((item) => _buildLokasiCard(context, item))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLokasiCard(BuildContext context, MappingLokasi item) {
    return GestureDetector(
      onTap: () => _showLabelDialog(context, item),
      child: Container(
        width: 80,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.namaJenis.isNotEmpty ? item.namaJenis : 'N/A',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              _buildStockBadge(item),
            ],
          ),
        ),
      ),
    );
  }

  void _showLabelDialog(BuildContext context, MappingLokasi item) {
    final vm = MappingLabelViewModel(
      repository: MappingRepository(api: ApiClient()),
    )..load(blok: item.blok, idLokasi: item.idLokasi);

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: LabelDialog(lokasi: item),
      ),
    ).whenComplete(() => vm.dispose());
  }
}
