class PackingPartialInfo {
  /// Total PCS partial (unique per NoBJPartial),
  /// sesuai field backend: totalPartialPcs
  final double totalPartialPcs;
  final List<PackingPartialRow> rows;

  const PackingPartialInfo({
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
  factory PackingPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    final rowsJson = (body['data'] as List?) ?? const [];

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return PackingPartialInfo(
      totalPartialPcs: _toDouble(body['totalPartialPcs']),
      rows: rowsJson
          .map((e) => PackingPartialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PackingPartialRow {
  final String noBJPartial;  // NoBJPartial
  final String noBJ;         // NoBJ
  final double pcs;          // Pcs (partial qty)

  /// Dari backend: 'JUAL' / null
  final String? sourceType;  // SourceType

  final String? noBJJual;        // NoBJJual
  final String? tanggalJual;     // TanggalJual (yyyy-MM-dd, sudah diformat di API)
  final int? idPembeli;          // IdPembeli
  final String? namaPembeli;     // NamaPembeli
  final String? remark;          // Remark

  const PackingPartialRow({
    required this.noBJPartial,
    required this.noBJ,
    required this.pcs,
    this.sourceType,
    this.noBJJual,
    this.tanggalJual,
    this.idPembeli,
    this.namaPembeli,
    this.remark,
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

  factory PackingPartialRow.fromJson(Map<String, dynamic> j) {
    return PackingPartialRow(
      noBJPartial: (j['NoBJPartial'] ?? '').toString(),
      noBJ: (j['NoBJ'] ?? '').toString(),
      pcs: _toDouble(j['Pcs']),

      sourceType: j['SourceType']?.toString(),      // 'JUAL' / null
      noBJJual: j['NoBJJual']?.toString(),

      tanggalJual: j['TanggalJual']?.toString(),
      idPembeli: _toInt(j['IdPembeli']),
      namaPembeli: j['NamaPembeli']?.toString(),
      remark: j['Remark']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBJPartial': noBJPartial,
    'NoBJ': noBJ,
    'Pcs': pcs,
    'SourceType': sourceType,
    'NoBJJual': noBJJual,
    'TanggalJual': tanggalJual,
    'IdPembeli': idPembeli,
    'NamaPembeli': namaPembeli,
    'Remark': remark,
  };
}
