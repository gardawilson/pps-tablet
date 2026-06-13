import 'package:flutter/foundation.dart';
import 'package:pps_tablet/features/mapping/model/mapping_layout_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';

enum EditorMode { lokasi, aisle, clear }

class MappingLayoutViewModel extends ChangeNotifier {
  final String blok;
  final List<MappingLokasi> lokasiList;

  MappingLayoutViewModel({required this.blok, required this.lokasiList}) {
    _grid = _buildGrid(_rows, _cols, []);
  }

  int _rows = 30;
  int _cols = 30;
  int get rows => _rows;
  int get cols => _cols;

  EditorMode _mode = EditorMode.lokasi;
  EditorMode get mode => _mode;

  late List<List<GridCell>> _grid;
  List<List<GridCell>> get grid => _grid;

  Set<int> get assignedLokasiIds => _grid
      .expand((row) => row)
      .where((c) => c.type == CellType.lokasi && c.idLokasi != null)
      .map((c) => c.idLokasi!)
      .toSet();

  List<MappingLokasi> get availableLokasi =>
      lokasiList.where((l) => !assignedLokasiIds.contains(l.idLokasi)).toList();

  bool get hasChanges =>
      _grid.expand((r) => r).any((c) => c.type != CellType.empty);

  // ── Grid construction ──────────────────────────────────────────────────────

  List<List<GridCell>> _buildGrid(
    int rows,
    int cols,
    List<List<GridCell>> old,
  ) {
    return List.generate(
      rows,
      (r) => List.generate(cols, (c) {
        if (r < old.length && c < old[r].length) return old[r][c];
        return GridCell(row: r, col: c);
      }),
    );
  }

  // ── Dimension controls ─────────────────────────────────────────────────────

  void setRows(int rows) {
    if (rows < 1 || rows > 60) return;
    _rows = rows;
    _grid = _buildGrid(_rows, _cols, _grid);
    notifyListeners();
  }

  void setCols(int cols) {
    if (cols < 1 || cols > 60) return;
    _cols = cols;
    _grid = _buildGrid(_rows, _cols, _grid);
    notifyListeners();
  }

  // ── Mode ───────────────────────────────────────────────────────────────────

  void setMode(EditorMode mode) {
    _mode = mode;
    notifyListeners();
  }

  // ── Cell interaction ───────────────────────────────────────────────────────

  void tapCell(int row, int col, {MappingLokasi? selectedLokasi}) {
    final cell = _grid[row][col];
    switch (_mode) {
      case EditorMode.aisle:
        cell.type =
            cell.type == CellType.aisle ? CellType.empty : CellType.aisle;
        cell.idLokasi = null;
        cell.lokasiLabel = null;
        cell.lokasiDescription = null;
      case EditorMode.lokasi:
        if (selectedLokasi != null) {
          cell.type = CellType.lokasi;
          cell.idLokasi = selectedLokasi.idLokasi;
          cell.lokasiLabel = selectedLokasi.label;
          cell.lokasiDescription = selectedLokasi.description;
        }
      case EditorMode.clear:
        cell.clear();
    }
    notifyListeners();
  }

  void resetGrid() {
    _grid = _buildGrid(_rows, _cols, []);
    notifyListeners();
  }
}
