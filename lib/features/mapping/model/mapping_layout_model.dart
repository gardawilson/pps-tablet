enum CellType { empty, aisle, lokasi }

class GridCell {
  final int row;
  final int col;
  CellType type;
  int? idLokasi;
  String? lokasiLabel;
  String? lokasiDescription;

  GridCell({
    required this.row,
    required this.col,
    this.type = CellType.empty,
    this.idLokasi,
    this.lokasiLabel,
    this.lokasiDescription,
  });

  GridCell copyWith({
    CellType? type,
    int? idLokasi,
    String? lokasiLabel,
    String? lokasiDescription,
  }) =>
      GridCell(
        row: row,
        col: col,
        type: type ?? this.type,
        idLokasi: idLokasi ?? this.idLokasi,
        lokasiLabel: lokasiLabel ?? this.lokasiLabel,
        lokasiDescription: lokasiDescription ?? this.lokasiDescription,
      );

  void clear() {
    type = CellType.empty;
    idLokasi = null;
    lokasiLabel = null;
    lokasiDescription = null;
  }
}
