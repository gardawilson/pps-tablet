import 'package:flutter/foundation.dart';

import '../model/mapping_layout_model.dart';
import '../model/mapping_lokasi_model.dart';
import '../repository/mapping_repository.dart';

class MappingLokasiViewModel extends ChangeNotifier {
  final MappingRepository repository;

  MappingLokasiViewModel({required this.repository});

  List<MappingLokasi> lokasiList = [];
  bool isLoading = false;
  String error = '';

  // Layout data
  int layoutRows = 0;
  int layoutCols = 0;
  List<List<GridCell>> layoutGrid = [];
  bool hasLayout = false;

  Future<void> loadLokasiByBlok(String blok) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      lokasiList = await repository.fetchLokasiByBlok(blok);
      await _loadLayout(blok);
    } catch (e) {
      error = e.toString();
      lokasiList = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLayout(String blok) async {
    try {
      final data = await repository.fetchLayout(blok);
      if (data == null) {
        hasLayout = false;
        return;
      }

      layoutRows = (data['rows'] as num).toInt();
      layoutCols = (data['cols'] as num).toInt();
      layoutGrid = List.generate(
        layoutRows,
        (r) => List.generate(layoutCols, (c) => GridCell(row: r, col: c)),
      );

      final cells = data['cells'] as List? ?? [];
      for (final c in cells) {
        final r = (c['row'] as num).toInt();
        final col = (c['col'] as num).toInt();
        if (r < layoutRows && col < layoutCols) {
          final cell = layoutGrid[r][col];
          final type = c['cellType'] as String;
          final rs = (c['rowSpan'] as num?)?.toInt() ?? 1;
          final cs = (c['colSpan'] as num?)?.toInt() ?? 1;

          cell.type = switch (type) {
            'lokasi' => CellType.lokasi,
            'aisle' => CellType.aisle,
            'label' => CellType.label,
            _ => CellType.empty,
          };
          cell.rowSpan = rs;
          cell.colSpan = cs;

          if (cell.type == CellType.lokasi) {
            cell.idLokasi = (c['idLokasi'] as num?)?.toInt();
            final lokasi = lokasiList
                .where((l) => l.idLokasi == cell.idLokasi)
                .firstOrNull;
            cell.lokasiLabel = lokasi?.label;
            cell.lokasiDescription = lokasi?.description;
          }

          if (cell.type == CellType.label) {
            cell.labelText = c['labelText'] as String?;
          }

          // Mark covered cells for span > 1
          if (rs > 1 || cs > 1) {
            for (int dr = 0; dr < rs; dr++) {
              for (int dc = 0; dc < cs; dc++) {
                if (dr == 0 && dc == 0) continue;
                final cr = r + dr;
                final cc = col + dc;
                if (cr < layoutRows && cc < layoutCols) {
                  layoutGrid[cr][cc].type = CellType.covered;
                  layoutGrid[cr][cc].originRow = r;
                  layoutGrid[cr][cc].originCol = col;
                }
              }
            }
          }
        }
      }

      hasLayout = cells.isNotEmpty;
    } catch (_) {
      hasLayout = false;
    }
  }
}
