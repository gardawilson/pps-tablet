class GilinganPartialInfo {
  final double totalPartialWeight;
  final List<GilinganPartialRow> rows;

  const GilinganPartialInfo({
    required this.totalPartialWeight,
    required this.rows,
  });

  /// Parse directly from the API envelope:
  /// { success, message, totalRows, totalPartialWeight, data: [...], meta: {...} }
  factory GilinganPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    final rowsJson = (body['data'] as List?) ?? const [];
    return GilinganPartialInfo(
      totalPartialWeight:
      (body['totalPartialWeight'] as num? ?? 0).toDouble(),
      rows: rowsJson
          .map((e) => GilinganPartialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GilinganPartialRow {
  final String noGilinganPartial; // NoGilinganPartial
  final String noGilingan;        // NoGilingan
  final double berat;             // Berat (partial weight)

  /// BROKER / INJECT / MIXER / WASHING / null
  final String? sourceType;       // SourceType

  final String? noProduksi;       // NoProduksi
  final String? tglProduksi;      // already formatted by API (yyyy-MM-dd)
  final int? idMesin;             // IdMesin
  final String? namaMesin;        // NamaMesin
  final int? idOperator;          // IdOperator
  final String? jam;              // Jam / JamKerja
  final String? shift;            // Shift

  const GilinganPartialRow({
    required this.noGilinganPartial,
    required this.noGilingan,
    required this.berat,
    this.sourceType,
    this.noProduksi,
    this.tglProduksi,
    this.idMesin,
    this.namaMesin,
    this.idOperator,
    this.jam,
    this.shift,
  });

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

  factory GilinganPartialRow.fromJson(Map<String, dynamic> j) {
    return GilinganPartialRow(
      noGilinganPartial: (j['NoGilinganPartial'] ?? '').toString(),
      noGilingan: (j['NoGilingan'] ?? '').toString(),
      berat: _toDouble(j['Berat']),

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
    'NoGilinganPartial': noGilinganPartial,
    'NoGilingan': noGilingan,
    'Berat': berat,
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
