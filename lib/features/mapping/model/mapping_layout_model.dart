enum CellType { empty, aisle, lokasi, label, covered }

class GridCell {
  final int row;
  final int col;
  CellType type;
  int? idLokasi;
  String? lokasiLabel;
  String? lokasiDescription;
  String? labelText;
  int rowSpan;
  int colSpan;
  int? originRow;
  int? originCol;

  GridCell({
    required this.row,
    required this.col,
    this.type = CellType.empty,
    this.idLokasi,
    this.lokasiLabel,
    this.lokasiDescription,
    this.labelText,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.originRow,
    this.originCol,
  });

  void clear() {
    type = CellType.empty;
    idLokasi = null;
    lokasiLabel = null;
    lokasiDescription = null;
    labelText = null;
    rowSpan = 1;
    colSpan = 1;
    originRow = null;
    originCol = null;
  }
}
