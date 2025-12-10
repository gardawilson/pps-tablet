// lib/features/reject/model/reject_partial_model.dart

class RejectPartialInfo {
  /// Total BERAT partial (unique per NoRejectPartial),
  /// sesuai field backend: totalPartialBerat
  final double totalPartialBerat;
  final List<RejectPartialRow> rows;

  const RejectPartialInfo({
    required this.totalPartialBerat,
    required this.rows,
  });

  /// Parse langsung dari envelope API:
  /// {
  ///   success,
  ///   message,
  ///   totalRows,
  ///   totalPartialBerat,
  ///   data: [...],
  ///   meta: { NoReject: ... }
  /// }
  factory RejectPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    final rowsJson = (body['data'] as List?) ?? const [];

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return RejectPartialInfo(
      totalPartialBerat: _toDouble(body['totalPartialBerat']),
      rows: rowsJson
          .map((e) => RejectPartialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RejectPartialRow {
  final String noRejectPartial;   // NoRejectPartial
  final String noReject;          // NoReject
  final double berat;             // Berat (partial berat)

  /// Dari backend: 'BROKER' / null
  final String? sourceType;       // SourceType

  final String? noProduksi;       // NoProduksi (broker)
  final String? tanggalProduksi;  // TanggalProduksi (yyyy-MM-dd, sudah diformat di API)
  final int? idMesin;             // IdMesin
  final String? namaMesin;        // NamaMesin
  final String? jamProduksi;      // JamProduksi
  final String? shift;            // Shift (string supaya fleksibel)

  const RejectPartialRow({
    required this.noRejectPartial,
    required this.noReject,
    required this.berat,
    this.sourceType,
    this.noProduksi,
    this.tanggalProduksi,
    this.idMesin,
    this.namaMesin,
    this.jamProduksi,
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

  factory RejectPartialRow.fromJson(Map<String, dynamic> j) {
    return RejectPartialRow(
      noRejectPartial: (j['NoRejectPartial'] ?? '').toString(),
      noReject: (j['NoReject'] ?? '').toString(),
      berat: _toDouble(j['Berat']),

      sourceType: j['SourceType']?.toString(),      // 'BROKER' / null
      noProduksi: j['NoProduksi']?.toString(),

      tanggalProduksi: j['TanggalProduksi']?.toString(),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: j['NamaMesin']?.toString(),
      jamProduksi: j['JamProduksi']?.toString(),
      shift: j['Shift']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoRejectPartial': noRejectPartial,
    'NoReject': noReject,
    'Berat': berat,
    'SourceType': sourceType,
    'NoProduksi': noProduksi,
    'TanggalProduksi': tanggalProduksi,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'JamProduksi': jamProduksi,
    'Shift': shift,
  };
}
