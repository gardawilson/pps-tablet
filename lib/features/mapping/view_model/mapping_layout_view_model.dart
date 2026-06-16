import 'package:flutter/foundation.dart';
import 'package:pps_tablet/features/mapping/model/mapping_layout_model.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';

enum EditorMode { lokasi, aisle, label }

class MappingLayoutViewModel extends ChangeNotifier {
  final String blok;
  final List<MappingLokasi> lokasiList;
  final MappingRepository repository;

  MappingLayoutViewModel({
    required this.blok,
    required this.lokasiList,
    required this.repository,
  }) {
    _grid = _buildGrid(_rows, _cols, []);
    _loadLayout();
  }

  int _rows = 30;
  int _cols = 30;
  int get rows => _rows;
  int get cols => _cols;

  EditorMode _mode = EditorMode.lokasi;
  EditorMode get mode => _mode;

  bool isLoading = false;
  bool isSaving = false;
  String error = '';

  late List<List<GridCell>> _grid;
  List<List<GridCell>> get grid => _grid;

  Set<int> get assignedLokasiIds => _grid
      .expand((row) => row)
      .where((c) => c.type == CellType.lokasi && c.idLokasi != null)
      .map((c) => c.idLokasi!)
      .toSet();

  List<MappingLokasi> get availableLokasi =>
      lokasiList.where((l) => !assignedLokasiIds.contains(l.idLokasi)).toList();

  bool get hasChanges => _grid.expand((r) => r).any(
        (c) => c.type != CellType.empty && c.type != CellType.covered,
      );

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
        if (cell.type == CellType.covered) return;
        cell.type =
            cell.type == CellType.aisle ? CellType.empty : CellType.aisle;
        cell.idLokasi = null;
        cell.lokasiLabel = null;
        cell.lokasiDescription = null;
      case EditorMode.label:
        // label placement via placeLabel()
        break;
      case EditorMode.lokasi:
        if (cell.type == CellType.covered) return;
        if (selectedLokasi != null) {
          cell.type = CellType.lokasi;
          cell.idLokasi = selectedLokasi.idLokasi;
          cell.lokasiLabel = selectedLokasi.label;
          cell.lokasiDescription = selectedLokasi.description;
        }
    }
    notifyListeners();
  }

  // ── Place / resize lokasi ────────────────────────────────────────────────

  bool canPlaceSpan(int row, int col, int rowSpan, int colSpan, {int? skipLokasiId}) {
    if (row + rowSpan > _rows || col + colSpan > _cols) return false;
    for (int r = row; r < row + rowSpan; r++) {
      for (int c = col; c < col + colSpan; c++) {
        final t = _grid[r][c].type;
        if (t == CellType.lokasi && _grid[r][c].idLokasi != skipLokasiId) {
          return false;
        }
      }
    }
    return true;
  }

  void _placeSpannedCell(int row, int col, int rowSpan, int colSpan) {
    for (int r = row; r < row + rowSpan; r++) {
      for (int c = col; c < col + colSpan; c++) {
        if (r == row && c == col) continue;
        _grid[r][c].type = CellType.covered;
        _grid[r][c].originRow = row;
        _grid[r][c].originCol = col;
      }
    }
  }

  void placeLokasi(int row, int col, MappingLokasi lokasi, {int rowSpan = 1, int colSpan = 1}) {
    final cell = _grid[row][col];
    if (cell.type == CellType.covered) return;
    _clearSpan(row, col);
    if (!canPlaceSpan(row, col, rowSpan, colSpan)) return;
    _clearArea(row, col, rowSpan, colSpan);
    final origin = _grid[row][col];
    origin.type = CellType.lokasi;
    origin.idLokasi = lokasi.idLokasi;
    origin.lokasiLabel = lokasi.label;
    origin.lokasiDescription = lokasi.description;
    origin.rowSpan = rowSpan;
    origin.colSpan = colSpan;
    _placeSpannedCell(row, col, rowSpan, colSpan);
    notifyListeners();
  }

  void resizeLokasi(int row, int col, int rowSpan, int colSpan) {
    final cell = _grid[row][col];
    if (cell.type != CellType.lokasi) return;
    final idLokasi = cell.idLokasi;
    final label = cell.lokasiLabel;
    final desc = cell.lokasiDescription;
    if (!canPlaceSpan(row, col, rowSpan, colSpan, skipLokasiId: idLokasi)) return;
    _clearSpan(row, col);
    _clearArea(row, col, rowSpan, colSpan);
    final origin = _grid[row][col];
    origin.type = CellType.lokasi;
    origin.idLokasi = idLokasi;
    origin.lokasiLabel = label;
    origin.lokasiDescription = desc;
    origin.rowSpan = rowSpan;
    origin.colSpan = colSpan;
    _placeSpannedCell(row, col, rowSpan, colSpan);
    notifyListeners();
  }

  void _clearSpan(int row, int col) {
    final cell = _grid[row][col];
    final rs = cell.rowSpan;
    final cs = cell.colSpan;
    for (int r = row; r < row + rs; r++) {
      for (int c = col; c < col + cs; c++) {
        _grid[r][c].clear();
      }
    }
  }

  void _clearArea(int row, int col, int rowSpan, int colSpan) {
    for (int r = row; r < row + rowSpan; r++) {
      for (int c = col; c < col + colSpan; c++) {
        _grid[r][c].clear();
      }
    }
  }

  // ── Place aisle (span support) ───────────────────────────────────────────

  bool canPlaceAisle(int row, int col, int rowSpan, int colSpan) =>
      canPlaceSpan(row, col, rowSpan, colSpan);

  void placeAisle(int row, int col, int rowSpan, int colSpan) {
    if (!canPlaceAisle(row, col, rowSpan, colSpan)) return;
    _clearArea(row, col, rowSpan, colSpan);
    final origin = _grid[row][col];
    origin.type = CellType.aisle;
    origin.rowSpan = rowSpan;
    origin.colSpan = colSpan;
    _placeSpannedCell(row, col, rowSpan, colSpan);
    notifyListeners();
  }

  // ── Place label (custom text, span support) ──────────────────────────────

  bool canPlaceLabel(int row, int col, int rowSpan, int colSpan) =>
      canPlaceSpan(row, col, rowSpan, colSpan);

  void placeLabel(int row, int col, String text, int rowSpan, int colSpan) {
    if (!canPlaceLabel(row, col, rowSpan, colSpan)) return;
    _clearArea(row, col, rowSpan, colSpan);
    final origin = _grid[row][col];
    origin.type = CellType.label;
    origin.labelText = text;
    origin.rowSpan = rowSpan;
    origin.colSpan = colSpan;
    _placeSpannedCell(row, col, rowSpan, colSpan);
    notifyListeners();
  }

  // ── Clear cell (handles span) ──────────────────────────────────────────────

  void clearCell(int row, int col) {
    final cell = _grid[row][col];

    if (cell.type == CellType.covered) {
      final or_ = cell.originRow!;
      final oc = cell.originCol!;
      _clearSpan(or_, oc);
    } else {
      _clearSpan(row, col);
    }

    notifyListeners();
  }

  // ── Move cell (drag-drop reposition) ─────────────────────────────────────

  void moveCell(int fromRow, int fromCol, int toRow, int toCol) {
    if (fromRow == toRow && fromCol == toCol) return;
    final src = _grid[fromRow][fromCol];
    if (src.type == CellType.empty || src.type == CellType.covered) return;

    final type = src.type;
    final idLokasi = src.idLokasi;
    final lokasiLabel = src.lokasiLabel;
    final lokasiDescription = src.lokasiDescription;
    final labelText = src.labelText;
    final rs = src.rowSpan;
    final cs = src.colSpan;

    if (toRow + rs > _rows || toCol + cs > _cols) return;

    _clearSpan(fromRow, fromCol);
    _clearArea(toRow, toCol, rs, cs);

    final dest = _grid[toRow][toCol];
    dest.type = type;
    dest.idLokasi = idLokasi;
    dest.lokasiLabel = lokasiLabel;
    dest.lokasiDescription = lokasiDescription;
    dest.labelText = labelText;
    dest.rowSpan = rs;
    dest.colSpan = cs;
    _placeSpannedCell(toRow, toCol, rs, cs);

    notifyListeners();
  }

  void resetGrid() {
    _grid = _buildGrid(_rows, _cols, []);
    notifyListeners();
  }

  // ── Load layout from backend ───────────────────────────────────────────────

  Future<void> _loadLayout() async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      final data = await repository.fetchLayout(blok);
      if (data != null) {
        _rows = (data['rows'] as num).toInt();
        _cols = (data['cols'] as num).toInt();
        _grid = _buildGrid(_rows, _cols, []);

        final cells = data['cells'] as List? ?? [];
        for (final c in cells) {
          final r = (c['row'] as num).toInt();
          final col = (c['col'] as num).toInt();
          if (r < _rows && col < _cols) {
            final cell = _grid[r][col];
            final type = c['cellType'] as String;
            final rs = (c['rowSpan'] as num?)?.toInt() ?? 1;
            final cs = (c['colSpan'] as num?)?.toInt() ?? 1;

            cell.type = switch (type) {
              'lokasi' => CellType.lokasi,
              'aisle' => CellType.aisle,
              'label' => CellType.label,
              _ => CellType.empty,
            };

            if (cell.type == CellType.lokasi) {
              cell.idLokasi = (c['idLokasi'] as num?)?.toInt();
              final lokasi = lokasiList
                  .where((l) => l.idLokasi == cell.idLokasi)
                  .firstOrNull;
              cell.lokasiLabel = lokasi?.label;
              cell.lokasiDescription = lokasi?.description;
            }

            if (cell.type == CellType.label) {
              final text = c['labelText'] as String? ?? '';
              placeLabel(r, col, text, rs, cs);
            }

            if (cell.type == CellType.aisle && (rs > 1 || cs > 1)) {
              placeAisle(r, col, rs, cs);
            }

            if (cell.type == CellType.lokasi && (rs > 1 || cs > 1)) {
              cell.rowSpan = rs;
              cell.colSpan = cs;
              _placeSpannedCell(r, col, rs, cs);
            }
          }
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Save layout to backend ─────────────────────────────────────────────────

  Future<bool> saveLayout() async {
    isSaving = true;
    notifyListeners();

    try {
      final cells = <Map<String, dynamic>>[];
      for (final row in _grid) {
        for (final cell in row) {
          if (cell.type == CellType.empty || cell.type == CellType.covered) {
            continue;
          }
          cells.add({
            'row': cell.row,
            'col': cell.col,
            'cellType': switch (cell.type) {
              CellType.lokasi => 'lokasi',
              CellType.aisle => 'aisle',
              CellType.label => 'label',
              _ => 'empty',
            },
            'idLokasi': cell.type == CellType.lokasi ? cell.idLokasi : null,
            'labelText': cell.type == CellType.label ? cell.labelText : null,
            'rowSpan': cell.rowSpan,
            'colSpan': cell.colSpan,
          });
        }
      }

      await repository.saveLayout(blok, {
        'rows': _rows,
        'cols': _cols,
        'cells': cells,
      });
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
