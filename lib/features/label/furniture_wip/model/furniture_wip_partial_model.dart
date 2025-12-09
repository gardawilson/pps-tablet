// lib/features/furniture_wip/model/packing_partial_model.dart

class FurnitureWipPartialInfo {
  /// Total PCS partial (unique per NoFurnitureWIPPartial),
  /// sesuai field backend: totalPartialPcs
  final double totalPartialPcs;
  final List<FurnitureWipPartialRow> rows;

  const FurnitureWipPartialInfo({
    required this.totalPartialPcs,
    required this.rows,
  });

  /// Parse langsung dari envelope API:
  /// {
  ///   success,
  ///   message,
  ///   totalRows,
  ///   totalPartialPcs,
  ///   data: [...],
  ///   meta: {...}
  /// }
  factory FurnitureWipPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    final rowsJson = (body['data'] as List?) ?? const [];

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return FurnitureWipPartialInfo(
      totalPartialPcs: _toDouble(body['totalPartialPcs']),
      rows: rowsJson
          .map((e) =>
          FurnitureWipPartialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FurnitureWipPartialRow {
  final String noFurnitureWipPartial; // NoFurnitureWIPPartial
  final String noFurnitureWip;        // NoFurnitureWIP
  final double pcs;                   // Pcs (partial qty)

  /// Untuk sekarang dari backend: 'INJECT' / null
  final String? sourceType;           // SourceType

  final String? noProduksi;           // NoProduksi
  final String? tglProduksi;          // yyyy-MM-dd (sudah diformat di API)
  final int? idMesin;                 // IdMesin
  final String? namaMesin;            // NamaMesin
  final int? idOperator;              // IdOperator
  final String? jam;                  // Jam
  final String? shift;                // Shift

  const FurnitureWipPartialRow({
    required this.noFurnitureWipPartial,
    required this.noFurnitureWip,
    required this.pcs,
    this.sourceType,
    this.noProduksi,
    this.tglProduksi,
    this.idMesin,
    this.namaMesin,
    this.idOperator,
    this.jam,
    this.shift,
  });

  bool get isConsumed => sourceType != null && sourceType!.isNotEmpty;

  // ---- helpers ----
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory FurnitureWipPartialRow.fromJson(Map<String, dynamic> j) {
    return FurnitureWipPartialRow(
      noFurnitureWipPartial: (j['NoFurnitureWIPPartial'] ?? '').toString(),
      noFurnitureWip: (j['NoFurnitureWIP'] ?? '').toString(),
      pcs: _toDouble(j['Pcs']),

      sourceType: j['SourceType']?.toString(),
      noProduksi: j['NoProduksi']?.toString(),

      tglProduksi: j['TglProduksi']?.toString(),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: j['NamaMesin']?.toString(),
      idOperator: _toInt(j['IdOperator']),
      jam: j['Jam']?.toString(),
      shift: j['Shift']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoFurnitureWIPPartial': noFurnitureWipPartial,
    'NoFurnitureWIP': noFurnitureWip,
    'Pcs': pcs,
    'SourceType': sourceType,
    'NoProduksi': noProduksi,
    'TglProduksi': tglProduksi,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'IdOperator': idOperator,
    'Jam': jam,
    'Shift': shift,
  };
}
