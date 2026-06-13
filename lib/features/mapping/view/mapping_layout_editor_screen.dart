import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/features/mapping/model/mapping_layout_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_layout_view_model.dart';

const Color _primary = Color(0xFF0D47A1);
const Color _aisleColor = Color(0xFFFFD600);
const Color _emptyColor = Color(0xFFF5F5F5);
const Color _lokasiColor = Colors.white;

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
      create: (_) => MappingLayoutViewModel(blok: blok, lokasiList: lokasiList),
      child: _EditorView(blok: blok, namaWarehouse: namaWarehouse),
    );
  }
}

class _EditorView extends StatelessWidget {
  final String blok;
  final String namaWarehouse;

  const _EditorView({required this.blok, required this.namaWarehouse});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLayoutViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editor Layout — Blok $blok',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            Text(
              namaWarehouse,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Reset
          TextButton.icon(
            onPressed: vm.hasChanges ? () => _confirmReset(context, vm) : null,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
          const SizedBox(width: 4),
          // Save
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: vm.hasChanges ? () => _onSave(context, vm) : null,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primary,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(context, vm),
          const Divider(height: 1),
          // Grid
          Expanded(child: _buildGrid(context, vm)),
          // Legend
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
          // Grid size controls
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
          // Mode selector
          const Text(
            'Mode:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          _ModeButton(
            icon: Icons.location_on_rounded,
            label: 'Lokasi',
            mode: EditorMode.lokasi,
            current: vm.mode,
            color: _primary,
            onTap: () => vm.setMode(EditorMode.lokasi),
          ),
          const SizedBox(width: 6),
          _ModeButton(
            icon: Icons.horizontal_rule_rounded,
            label: 'Jalan',
            mode: EditorMode.aisle,
            current: vm.mode,
            color: const Color(0xFFE65100),
            onTap: () => vm.setMode(EditorMode.aisle),
          ),
          const SizedBox(width: 6),
          _ModeButton(
            icon: Icons.clear_rounded,
            label: 'Hapus',
            mode: EditorMode.clear,
            current: vm.mode,
            color: Colors.grey.shade600,
            onTap: () => vm.setMode(EditorMode.clear),
          ),
          // Assigned counter
          const SizedBox(width: 16),
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
        ],
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context, MappingLayoutViewModel vm) {
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column numbers header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 28), // row number gutter
                for (int c = 0; c < vm.cols; c++)
                  SizedBox(
                    width: 64,
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
            const SizedBox(height: 4),
            // Grid rows
            for (int r = 0; r < vm.rows; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row number
                  SizedBox(
                    width: 28,
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
                  // Cells
                  for (int c = 0; c < vm.cols; c++)
                    _GridCell(
                      cell: vm.grid[r][c],
                      mode: vm.mode,
                      onTap: () => _onCellTap(context, vm, r, c),
                    ),
                ],
              ),
          ],
        ),
      ),
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
          const SizedBox(width: 20),
          _legendItem(_aisleColor, Colors.orange.shade800, 'Jalan / Aisle'),
          const SizedBox(width: 20),
          _legendItem(_emptyColor, Colors.grey, 'Kosong'),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color fg, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: border
                ? Border.all(color: _primary.withValues(alpha: 0.4))
                : Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
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

    if (vm.mode == EditorMode.aisle || vm.mode == EditorMode.clear) {
      vm.tapCell(row, col);
      return;
    }

    // Mode lokasi
    if (cell.type == CellType.lokasi) {
      // sudah ada lokasi → tawarkan hapus atau ganti
      _showCellOptions(context, vm, row, col, cell);
      return;
    }

    // Cell kosong → pilih lokasi
    _showLokasiPicker(context, vm, row, col);
  }

  void _showLokasiPicker(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
  ) {
    final available = vm.availableLokasi;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua lokasi sudah ditempatkan')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LokasiPickerSheet(
        available: available,
        onSelected: (lokasi) {
          vm.tapCell(row, col, selectedLokasi: lokasi);
        },
      ),
    );
  }

  void _showCellOptions(
    BuildContext context,
    MappingLayoutViewModel vm,
    int row,
    int col,
    GridCell cell,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CellOptionsSheet(
        cell: cell,
        onRemove: () {
          vm.tapCell(row, col);
        },
        onReplace: () {
          Navigator.pop(context);
          vm.tapCell(row, col); // clear dulu
          _showLokasiPicker(context, vm, row, col);
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

  void _onSave(BuildContext context, MappingLayoutViewModel vm) {
    // TODO: kirim ke backend saat API sudah siap
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Layout blok $blok disimpan (${vm.assignedLokasiIds.length} lokasi)',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Grid Cell Widget ──────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  final GridCell cell;
  final EditorMode mode;
  final VoidCallback onTap;

  const _GridCell({
    required this.cell,
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAisle = cell.type == CellType.aisle;
    final isLokasi = cell.type == CellType.lokasi;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 56,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isAisle
              ? _aisleColor
              : isLokasi
              ? _lokasiColor
              : _emptyColor,
          borderRadius: BorderRadius.circular(6),
          border: isLokasi
              ? Border.all(color: _primary.withValues(alpha: 0.5), width: 1.5)
              : isAisle
              ? Border.all(color: Colors.orange.shade700.withValues(alpha: 0.5))
              : Border.all(color: Colors.grey.shade300),
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
            : Center(
                child: Icon(Icons.add, size: 14, color: Colors.grey.shade300),
              ),
      ),
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

// ── Mode Button ───────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditorMode mode;
  final EditorMode current;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.mode,
    required this.current,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = mode == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lokasi Picker Sheet ───────────────────────────────────────────────────────

class _LokasiPickerSheet extends StatefulWidget {
  final List<MappingLokasi> available;
  final ValueChanged<MappingLokasi> onSelected;

  const _LokasiPickerSheet({required this.available, required this.onSelected});

  @override
  State<_LokasiPickerSheet> createState() => _LokasiPickerSheetState();
}

class _LokasiPickerSheetState extends State<_LokasiPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.available
        .where(
          (l) =>
              l.label.toLowerCase().contains(_search.toLowerCase()) ||
              l.description.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Pilih Lokasi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  '${widget.available.length} tersedia',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari lokasi...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final lokasi = filtered[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lokasi.label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  title: Text(
                    lokasi.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: lokasi.description.isNotEmpty
                      ? Text(
                          lokasi.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(lokasi);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cell Options Sheet ────────────────────────────────────────────────────────

class _CellOptionsSheet extends StatelessWidget {
  final GridCell cell;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _CellOptionsSheet({
    required this.cell,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Cell info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cell.lokasiLabel ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _primary,
                        ),
                      ),
                      if (cell.lokasiDescription?.isNotEmpty == true)
                        Text(
                          cell.lokasiDescription!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(Icons.swap_horiz_rounded, color: _primary),
            title: const Text(
              'Ganti Lokasi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              onReplace();
            },
          ),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
            title: const Text(
              'Hapus dari Grid',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              onRemove();
            },
          ),
        ],
      ),
    );
  }
}
