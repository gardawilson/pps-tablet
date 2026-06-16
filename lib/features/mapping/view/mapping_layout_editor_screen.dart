import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/model/mapping_layout_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_layout_view_model.dart';

// Data class untuk drag-drop antar sel grid
class _CellMoveData {
  final int row;
  final int col;
  const _CellMoveData(this.row, this.col);
}

// Hover preview state — held in ValueNotifier to avoid full tree rebuild
class _HoverState {
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final Color color;
  const _HoverState({
    required this.row,
    required this.col,
    required this.rowSpan,
    required this.colSpan,
    required this.color,
  });
}

const Color _primary = Color(0xFF0D47A1);
const Color _aisleColor = Color(0xFFFFD600);
const Color _emptyColor = Colors.transparent;
const Color _lokasiColor = Colors.white;
const Color _labelColor = Color(0xFFE8F5E9);

const double _slotW = 67.0;
const double _slotH = 59.0;

class MappingLayoutEditorScreen extends StatelessWidget {
  final String blok;
  final String namaWarehouse;
  final List<MappingLokasi> lokasiList;

  const MappingLayoutEditorScreen({
    super.key,
    required this.blok,
    required this.namaWarehouse,
    required this.lokasiList,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MappingLayoutViewModel(
        blok: blok,
        lokasiList: lokasiList,
        repository: MappingRepository(api: ApiClient()),
      ),
      child: _EditorView(blok: blok, namaWarehouse: namaWarehouse),
    );
  }
}

// ── Editor View ───────────────────────────────────────────────────────────────

class _EditorView extends StatefulWidget {
  final String blok;
  final String namaWarehouse;

  const _EditorView({required this.blok, required this.namaWarehouse});

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  bool _panelCollapsed = false;

  // ValueNotifier so hover updates only rebuild the overlay, not the full grid
  final _hoverNotifier = ValueNotifier<_HoverState?>(null);

  // Grab-point offset in cell units (set when drag starts)
  int _grabDeltaRow = 0;
  int _grabDeltaCol = 0;

  // Aisle drag-paint tracking
  int _lastPaintRow = -1;
  int _lastPaintCol = -1;

  @override
  void dispose() {
    _hoverNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLayoutViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildToolbar(context, vm),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      // Grid area
                      Expanded(child: _buildGrid(context, vm)),
                      // Right panel
                      _buildRightPanel(context, vm),
                    ],
                  ),
                ),
                _buildLegend(),
              ],
            ),
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────────

  Widget _buildToolbar(BuildContext context, MappingLayoutViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text(
            'Ukuran Grid:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          _DimControl(
            icon: Icons.table_rows_rounded,
            label: 'Baris',
            value: vm.rows,
            onDecrement: () => vm.setRows(vm.rows - 1),
            onIncrement: () => vm.setRows(vm.rows + 1),
          ),
          const SizedBox(width: 12),
          _DimControl(
            icon: Icons.view_column_rounded,
            label: 'Kolom',
            value: vm.cols,
            onDecrement: () => vm.setCols(vm.cols - 1),
            onIncrement: () => vm.setCols(vm.cols + 1),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${vm.assignedLokasiIds.length} / ${vm.lokasiList.length} lokasi',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: vm.hasChanges ? () => _confirmReset(context, vm) : null,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              disabledForegroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 6),
          if (vm.isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton.icon(
              onPressed: vm.hasChanges ? () => _onSave(context, vm) : null,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Simpan'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
        ],
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  static const double _gutterW = 28.0;
  static const double _headerH = 20.0;

  Widget _buildGrid(BuildContext context, MappingLayoutViewModel vm) {
    final gridW = vm.cols * _slotW;
    final gridH = vm.rows * _slotH;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.3,
      maxScale: 2.0,
      panEnabled: vm.mode != EditorMode.aisle,
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
                for (int r = 0; r < vm.rows; r++)
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
                      for (int c = 0; c < vm.cols; c++)
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
                GestureDetector(
                  onPanStart: vm.mode == EditorMode.aisle
                      ? (d) => _onAislePaint(d.localPosition, vm)
                      : null,
                  onPanUpdate: vm.mode == EditorMode.aisle
                      ? (d) => _onAislePaint(d.localPosition, vm)
                      : null,
                  onPanEnd: vm.mode == EditorMode.aisle
                      ? (_) {
                          _lastPaintRow = -1;
                          _lastPaintCol = -1;
                        }
                      : null,
                  child: SizedBox(
                    width: gridW,
                    height: gridH,
                    child: Stack(
                      children: [
                        for (int r = 0; r < vm.rows; r++)
                          for (int c = 0; c < vm.cols; c++)
                            if (vm.grid[r][c].type != CellType.covered)
                              Positioned(
                                left: c * _slotW,
                                top: r * _slotH,
                                child: _GridCell(
                                  cell: vm.grid[r][c],
                                  mode: vm.mode,
                                  width: vm.grid[r][c].type == CellType.empty
                                      ? _slotW
                                      : vm.grid[r][c].colSpan * _slotW - 3,
                                  height: vm.grid[r][c].type == CellType.empty
                                      ? _slotH
                                      : vm.grid[r][c].rowSpan * _slotH - 3,
                                  onTap: () => _onCellTap(context, vm, r, c),
                                  onGrabDelta: (dr, dc) {
                                    _grabDeltaRow = dr;
                                    _grabDeltaCol = dc;
                                  },
                                  onDropLokasi: (lokasi) {
                                    vm.placeLokasi(r, c, lokasi);
                                    _hoverNotifier.value = null;
                                  },
                                  onDropMove: (data) {
                                    final destRow = (r - _grabDeltaRow).clamp(
                                      0,
                                      vm.rows - 1,
                                    );
                                    final destCol = (c - _grabDeltaCol).clamp(
                                      0,
                                      vm.cols - 1,
                                    );
                                    vm.moveCell(
                                      data.row,
                                      data.col,
                                      destRow,
                                      destCol,
                                    );
                                    _hoverNotifier.value = null;
                                  },
                                  onHoverUpdate: (dragData) {
                                    int rs = 1, cs = 1;
                                    Color color = _primary;
                                    int deltaRow = 0, deltaCol = 0;
                                    if (dragData is _CellMoveData) {
                                      final src =
                                          vm.grid[dragData.row][dragData.col];
                                      rs = src.rowSpan;
                                      cs = src.colSpan;
                                      color = switch (src.type) {
                                        CellType.aisle => const Color(
                                          0xFFE65100,
                                        ),
                                        CellType.label => const Color(
                                          0xFF2E7D32,
                                        ),
                                        _ => _primary,
                                      };
                                      deltaRow = _grabDeltaRow;
                                      deltaCol = _grabDeltaCol;
                                    }
                                    final hoverRow = (r - deltaRow).clamp(
                                      0,
                                      vm.rows - 1,
                                    );
                                    final hoverCol = (c - deltaCol).clamp(
                                      0,
                                      vm.cols - 1,
                                    );
                                    _hoverNotifier.value = _HoverState(
                                      row: hoverRow,
                                      col: hoverCol,
                                      rowSpan: rs,
                                      colSpan: cs,
                                      color: color,
                                    );
                                  },
                                  onHoverLeave: () {
                                    _hoverNotifier.value = null;
                                  },
                                ),
                              ),
                        // Hover preview overlay — only this rebuilds on hover change
                        ValueListenableBuilder<_HoverState?>(
                          valueListenable: _hoverNotifier,
                          builder: (_, hover, __) {
                            if (hover == null) return const SizedBox.shrink();
                            return Positioned(
                              left: hover.col * _slotW,
                              top: hover.row * _slotH,
                              child: IgnorePointer(
                                child: Container(
                                  width: hover.colSpan * _slotW - 3,
                                  height: hover.rowSpan * _slotH - 3,
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: hover.color.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: hover.color,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ), // GestureDetector
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAislePaint(Offset localPos, MappingLayoutViewModel vm) {
    final col = (localPos.dx / _slotW).floor();
    final row = (localPos.dy / _slotH).floor();
    if (row == _lastPaintRow && col == _lastPaintCol) return;
    _lastPaintRow = row;
    _lastPaintCol = col;
    if (row >= 0 && row < vm.rows && col >= 0 && col < vm.cols) {
      if (vm.grid[row][col].type == CellType.empty) {
        vm.placeAisle(row, col, 1, 1);
      }
    }
  }

  // ── Right Panel ────────────────────────────────────────────────────────────

  Widget _buildRightPanel(BuildContext context, MappingLayoutViewModel vm) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _panelCollapsed ? 40 : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: _panelCollapsed
            ? _buildCollapsedPanel()
            : _buildExpandedPanel(vm),
      ),
    );
  }

  Widget _buildCollapsedPanel() {
    return Column(
      children: [
        const SizedBox(height: 6),
        Tooltip(
          message: 'Buka panel',
          child: InkWell(
            onTap: () => setState(() => _panelCollapsed = false),
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox(
              width: 40,
              height: 36,
              child: Icon(
                Icons.chevron_left_rounded,
                color: _primary,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Lokasi',
          child: const Icon(
            Icons.location_on_rounded,
            size: 18,
            color: _primary,
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Jalan / Aisle',
          child: const Icon(
            Icons.horizontal_rule_rounded,
            size: 18,
            color: Color(0xFFE65100),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Label',
          child: const Icon(
            Icons.label_rounded,
            size: 18,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedPanel(MappingLayoutViewModel vm) {
    final available = vm.availableLokasi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          height: 42,
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Row(
            children: [
              Text(
                'Alat',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Tutup panel',
                child: InkWell(
                  onTap: () => setState(() => _panelCollapsed = true),
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFEEEEEE)),

        // ── Tool selector ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            children: [
              _ToolButton(
                icon: Icons.location_on_rounded,
                label: 'Lokasi',
                description: 'Seret ke grid',
                mode: EditorMode.lokasi,
                current: vm.mode,
                activeColor: _primary,
                onTap: () => vm.setMode(EditorMode.lokasi),
              ),
              const SizedBox(height: 4),
              _ToolButton(
                icon: Icons.gesture_rounded,
                label: 'Aisle',
                description: 'Lukis jalur',
                mode: EditorMode.aisle,
                current: vm.mode,
                activeColor: const Color(0xFFE65100),
                onTap: () => vm.setMode(EditorMode.aisle),
              ),
              const SizedBox(height: 4),
              _ToolButton(
                icon: Icons.label_rounded,
                label: 'Label',
                description: 'Tap sel kosong',
                mode: EditorMode.label,
                current: vm.mode,
                activeColor: const Color(0xFF2E7D32),
                onTap: () => vm.setMode(EditorMode.label),
              ),
            ],
          ),
        ),
        Container(height: 1, color: const Color(0xFFEEEEEE)),

        // ── Context area ─────────────────────────────────────────────────────
        if (vm.mode == EditorMode.lokasi) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Text(
                  'Inventaris',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${available.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 28,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Semua lokasi\ntelah ditempatkan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    itemCount: available.length,
                    itemBuilder: (_, i) =>
                        _DraggableLokasi(lokasi: available[i]),
                  ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.mode == EditorMode.aisle
                          ? Icons.gesture_rounded
                          : Icons.label_rounded,
                      size: 28,
                      color: vm.mode == EditorMode.aisle
                          ? const Color(0xFFE65100).withValues(alpha: 0.4)
                          : const Color(0xFF2E7D32).withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _modePanelHint(vm.mode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(_lokasiColor, _primary, 'Lokasi', border: true),
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
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ── Interactions ───────────────────────────────────────────────────────────

  void _onCellTap(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
  ) {
    final cell = vm.grid[row][col];
    final originRow = cell.type == CellType.covered ? cell.originRow! : row;
    final originCol = cell.type == CellType.covered ? cell.originCol! : col;
    final origin = vm.grid[originRow][originCol];

    // Tap sel yang sudah berisi → popup Resize / Hapus (berlaku di semua mode)
    if (origin.type != CellType.empty) {
      _showCellOptions(context, vm, originRow, originCol, origin);
      return;
    }

    // Sel kosong — tindakan sesuai mode aktif
    switch (vm.mode) {
      case EditorMode.aisle:
        vm.placeAisle(row, col, 1, 1);
      case EditorMode.lokasi:
        break; // lokasi hanya bisa via drag dari panel
      case EditorMode.label:
        _showNewLabelDialog(context, vm, row, col);
    }
  }

  void _showCellOptions(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
    GridCell cell,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(switch (cell.type) {
          CellType.lokasi => 'Lokasi: ${cell.lokasiLabel ?? ''}',
          CellType.aisle => 'Jalan / Aisle',
          CellType.label => 'Label: ${cell.labelText ?? ''}',
          _ => 'Sel',
        }, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cell.type == CellType.label)
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text('Edit Label'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLabelEditor(
                    context,
                    vm,
                    row,
                    col,
                    existing: cell.labelText,
                    initRowSpan: cell.rowSpan,
                    initColSpan: cell.colSpan,
                  );
                },
              )
            else
              ListTile(
                leading: Icon(
                  Icons.open_with_rounded,
                  color: switch (cell.type) {
                    CellType.lokasi => _primary,
                    CellType.aisle => const Color(0xFFE65100),
                    _ => Colors.grey,
                  },
                ),
                title: const Text('Resize'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showResizeForCell(context, vm, row, col, cell);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                vm.clearCell(row, col);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showResizeForCell(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
    GridCell cell,
  ) {
    switch (cell.type) {
      case CellType.lokasi:
        _showSpanPicker(
          context: context,
          title: 'Ukuran Lokasi',
          activeColor: _primary,
          row: row,
          col: col,
          initRowSpan: cell.rowSpan,
          initColSpan: cell.colSpan,
          canPlace: (rs, cs) =>
              vm.canPlaceSpan(row, col, rs, cs, skipLokasiId: cell.idLokasi),
          onConfirm: (rs, cs) => vm.resizeLokasi(row, col, rs, cs),
        );
      case CellType.aisle:
        _showSpanPicker(
          context: context,
          title: 'Ukuran Jalan / Aisle',
          activeColor: const Color(0xFFE65100),
          row: row,
          col: col,
          initRowSpan: cell.rowSpan,
          initColSpan: cell.colSpan,
          canPlace: (rs, cs) => vm.canPlaceAisle(row, col, rs, cs),
          onConfirm: (rs, cs) => vm.placeAisle(row, col, rs, cs),
        );
      default:
        break;
    }
  }

  String _modePanelHint(EditorMode mode) => switch (mode) {
    EditorMode.aisle => 'Tap sel kosong\ndi grid untuk\nmenempatkan jalan',
    EditorMode.label => 'Tap sel kosong\ndi grid untuk\nmenambah label',
    EditorMode.lokasi => '',
  };

  // ── Generic span picker ────────────────────────────────────────────────────

  void _showSpanPicker({
    required BuildContext context,
    required String title,
    required Color activeColor,
    required int row,
    required int col,
    required bool Function(int rs, int cs) canPlace,
    required void Function(int rs, int cs) onConfirm,
    int initRowSpan = 1,
    int initColSpan = 1,
    int maxRowSpan = 60,
    int maxColSpan = 60,
  }) {
    final rowCtrl = TextEditingController(text: '$initRowSpan');
    final colCtrl = TextEditingController(text: '$initColSpan');

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          String? rowErr;
          String? colErr;

          void validate() {
            final rs = int.tryParse(rowCtrl.text);
            final cs = int.tryParse(colCtrl.text);
            setSt(() {
              rowErr = rs == null || rs < 1 || rs > maxRowSpan
                  ? 'Masukkan angka 1–$maxRowSpan'
                  : null;
              colErr = cs == null || cs < 1 || cs > maxColSpan
                  ? 'Masukkan angka 1–$maxColSpan'
                  : null;
              if (rowErr == null && colErr == null && !canPlace(rs!, cs!)) {
                colErr = 'Melebihi batas atau terhalang sel lain';
              }
            });
          }

          final isValid = () {
            final rs = int.tryParse(rowCtrl.text);
            final cs = int.tryParse(colCtrl.text);
            return rs != null &&
                cs != null &&
                rs >= 1 &&
                rs <= maxRowSpan &&
                cs >= 1 &&
                cs <= maxColSpan &&
                canPlace(rs, cs);
          };

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _spanTextField(
                          controller: rowCtrl,
                          label: 'Baris (tinggi)',
                          hint: '1–$maxRowSpan',
                          errorText: rowErr,
                          activeColor: activeColor,
                          onChanged: (_) => validate(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        child: Text(
                          '×',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _spanTextField(
                          controller: colCtrl,
                          label: 'Kolom (lebar)',
                          hint: '1–$maxColSpan',
                          errorText: colErr,
                          activeColor: activeColor,
                          onChanged: (_) => validate(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isValid()
                    ? () {
                        Navigator.pop(ctx);
                        onConfirm(
                          int.parse(rowCtrl.text),
                          int.parse(colCtrl.text),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(backgroundColor: activeColor),
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _spanTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? errorText,
    required Color activeColor,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 2,
        errorStyle: const TextStyle(fontSize: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: activeColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  // ── New label dialog (text only, places 1×1) ──────────────────────────────

  void _showNewLabelDialog(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
  ) {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Label Teks',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 280,
              child: TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 2,
                onChanged: (_) => setSt(() {}),
                decoration: InputDecoration(
                  hintText: 'Masukkan teks label...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: textCtrl.text.trim().isNotEmpty
                    ? () {
                        vm.placeLabel(row, col, textCtrl.text.trim(), 1, 1);
                        Navigator.pop(ctx);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Label editor (edit text + resize existing) ─────────────────────────────

  void _showLabelEditor(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col, {
    String? existing,
    int initRowSpan = 1,
    int initColSpan = 1,
  }) {
    final textCtrl = TextEditingController(text: existing ?? '');
    final rowCtrl = TextEditingController(text: '$initRowSpan');
    final colCtrl = TextEditingController(text: '$initColSpan');
    const activeColor = Color(0xFF2E7D32);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          String? rowErr;
          String? colErr;

          void validate() {
            final rs = int.tryParse(rowCtrl.text);
            final cs = int.tryParse(colCtrl.text);
            setSt(() {
              rowErr = rs == null || rs < 1 ? 'Min 1' : null;
              colErr = cs == null || cs < 1 ? 'Min 1' : null;
              if (rowErr == null &&
                  colErr == null &&
                  !vm.canPlaceLabel(row, col, rs!, cs!)) {
                colErr = 'Melebihi batas atau terhalang sel lain';
              }
            });
          }

          bool isValid() {
            final rs = int.tryParse(rowCtrl.text);
            final cs = int.tryParse(colCtrl.text);
            return rs != null &&
                cs != null &&
                rs >= 1 &&
                cs >= 1 &&
                textCtrl.text.trim().isNotEmpty &&
                vm.canPlaceLabel(row, col, rs, cs);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Label Teks',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textCtrl,
                    autofocus: true,
                    maxLines: 2,
                    onChanged: (_) => setSt(() {}),
                    decoration: InputDecoration(
                      hintText: 'Masukkan teks label...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: activeColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ukuran (baris × kolom):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _spanTextField(
                          controller: rowCtrl,
                          label: 'Baris',
                          hint: '≥1',
                          errorText: rowErr,
                          activeColor: activeColor,
                          onChanged: (_) => validate(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                        child: Text(
                          '×',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _spanTextField(
                          controller: colCtrl,
                          label: 'Kolom',
                          hint: '≥1',
                          errorText: colErr,
                          activeColor: activeColor,
                          onChanged: (_) => validate(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isValid()
                    ? () {
                        vm.placeLabel(
                          row,
                          col,
                          textCtrl.text.trim(),
                          int.parse(rowCtrl.text),
                          int.parse(colCtrl.text),
                        );
                        Navigator.pop(ctx);
                      }
                    : null,
                style: FilledButton.styleFrom(backgroundColor: activeColor),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, MappingLayoutViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Grid?'),
        content: const Text(
          'Semua penempatan lokasi dan jalan akan dihapus. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              vm.resetGrid();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context, MappingLayoutViewModel vm) async {
    final success = await vm.saveLayout();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Layout blok ${widget.blok} berhasil disimpan'
              : 'Gagal menyimpan: ${vm.error}',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Draggable Lokasi Item ─────────────────────────────────────────────────────

class _DraggableLokasi extends StatelessWidget {
  final MappingLokasi lokasi;

  const _DraggableLokasi({required this.lokasi});

  @override
  Widget build(BuildContext context) {
    final chip = _buildChip();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LongPressDraggable<MappingLokasi>(
        data: lokasi,
        delay: const Duration(milliseconds: 200),
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: _buildChip(isDragging: true),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: chip),
        child: chip,
      ),
    );
  }

  Widget _buildChip({bool isDragging = false}) {
    return Container(
      width: 196,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDragging ? _primary.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging ? _primary : Colors.grey.shade200,
          width: isDragging ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lokasi.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: _primary,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lokasi.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (lokasi.description.isNotEmpty)
                  Text(
                    lokasi.description,
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Cell ─────────────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  final GridCell cell;
  final EditorMode mode;
  final double width;
  final double height;
  final VoidCallback onTap;
  final ValueChanged<MappingLokasi> onDropLokasi;
  final ValueChanged<_CellMoveData> onDropMove;
  final ValueChanged<Object> onHoverUpdate;
  final VoidCallback onHoverLeave;
  final void Function(int grabRow, int grabCol) onGrabDelta;

  const _GridCell({
    required this.cell,
    required this.mode,
    required this.width,
    required this.height,
    required this.onTap,
    required this.onDropLokasi,
    required this.onDropMove,
    required this.onHoverUpdate,
    required this.onHoverLeave,
    required this.onGrabDelta,
  });

  bool get _isDraggable => cell.type != CellType.empty;

  @override
  Widget build(BuildContext context) {
    final target = DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        if (details.data is _CellMoveData) {
          final d = details.data as _CellMoveData;
          return d.row != cell.row || d.col != cell.col;
        }
        return cell.type != CellType.lokasi;
      },
      onAcceptWithDetails: (details) {
        if (details.data is MappingLokasi) {
          onDropLokasi(details.data as MappingLokasi);
        } else if (details.data is _CellMoveData) {
          onDropMove(details.data as _CellMoveData);
        }
      },
      onMove: (details) => onHoverUpdate(details.data),
      onLeave: (_) => onHoverLeave(),
      builder: (context, _, __) {
        return GestureDetector(onTap: onTap, child: _buildCell());
      },
    );

    if (!_isDraggable) return target;

    return LongPressDraggable<_CellMoveData>(
      data: _CellMoveData(cell.row, cell.col),
      delay: const Duration(milliseconds: 300),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(opacity: 0.9, child: _buildCell()),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: target),
      child: target,
    );
  }

  Widget _buildCell() {
    final isAisle = cell.type == CellType.aisle;
    final isLokasi = cell.type == CellType.lokasi;
    final isLabel = cell.type == CellType.label;

    final Color bgColor = isAisle
        ? _aisleColor
        : isLokasi
        ? _lokasiColor
        : isLabel
        ? _labelColor
        : _emptyColor;

    final isEmpty = !isAisle && !isLokasi && !isLabel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: height,
      margin: isEmpty ? EdgeInsets.zero : const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isEmpty ? 0 : 6),
        border: isLokasi
            ? Border.all(color: _primary.withValues(alpha: 0.5), width: 1.5)
            : isAisle
            ? Border.all(color: Colors.orange.shade700.withValues(alpha: 0.5))
            : isLabel
            ? Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.5))
            : Border.all(color: const Color(0xFFDEE2E6), width: 0.5),
        boxShadow: isLokasi
            ? [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.12),
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
                padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      height: 1,
                    ),
                  ),
                  if (cell.lokasiDescription != null &&
                      cell.lokasiDescription!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      cell.lokasiDescription!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7,
                        color: Colors.grey[500],
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── Dimension Control ─────────────────────────────────────────────────────────

class _DimControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _DimControl({
    required this.icon,
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(width: 4),
        _iconBtn(Icons.remove, onDecrement),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        _iconBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: Colors.grey[700]),
    ),
  );
}

// ── Tool Button ───────────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final EditorMode mode;
  final EditorMode current;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.mode,
    required this.current,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = mode == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.45)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 15,
                color: isActive ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? activeColor : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? activeColor.withValues(alpha: 0.7)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
