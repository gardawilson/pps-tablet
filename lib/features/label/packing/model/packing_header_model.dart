// lib/features/packing/model/reject_header_model.dart

class PackingHeader {
  // Core
  final String noBJ;        // NoBJ
  final String dateCreate;  // DateCreate (string apa adanya dari API)
  final int idBJ;           // IdBJ
  final String? namaBJ;     // NamaBJ (join MstBarangJadi)

  /// Pcs di sini SUDAH dikurangi total partial
  /// sesuai logic di service (kalau IsPartial = 1).
  final double? pcs;

  /// Berat dari header (tidak dikurangi partial di service)
  final double? berat;

  final int isPartial;        // IsPartial (0 / 1)
  final int? idWarehouse;     // IdWarehouse (boleh null)
  final String? blok;         // Blok
  final String? idLokasi;     // IdLokasi (stringified)

  // 🔹 Info sumber produksi
  /// 'PACKING' / 'INJECT' / 'BONGKAR_SUSUN' / 'RETUR'
  final String? outputType;

  /// NoPacking / NoProduksi / NoBongkarSusun / NoRetur
  /// (BD./S./BG./L.***** kalau pakai prefix)
  final String? outputCode;

  /// NamaMesin / 'Bongkar Susun' / NamaPembeli
  final String? outputNamaMesin;

  const PackingHeader({
    required this.noBJ,
    required this.dateCreate,
    required this.idBJ,
    this.namaBJ,
    this.pcs,
    this.berat,
    required this.isPartial,
    this.idWarehouse,
    this.blok,
    this.idLokasi,
    this.outputType,
    this.outputCode,
    this.outputNamaMesin,
  });

  // ---------------------------------------------------------------------------
  // Convenience getters buat UI
  // ---------------------------------------------------------------------------

  bool get isPartialBool => isPartial == 1;
  bool get hasLocation => (idLokasi ?? '').isNotEmpty;

  /// Label singkat untuk di table, kalau mau dipakai:
  /// contoh: "S.0000029950 | MESIN 280T"
  String get outputDisplay {
    if ((outputCode ?? '').isEmpty && (outputNamaMesin ?? '').isEmpty) {
      return '-';
    }
    if ((outputCode ?? '').isEmpty) return outputNamaMesin ?? '-';
    if ((outputNamaMesin ?? '').isEmpty) return outputCode ?? '-';
    return '$outputCode | $outputNamaMesin';
  }

  // ---------------------------------------------------------------------------
  // JSON helpers
  // ---------------------------------------------------------------------------

  factory PackingHeader.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;

      // handle boolean dari API: true/false
      if (v is bool) {
        return v ? 1 : 0;
      }

      if (v is num) return v.toInt();

      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true') return 1;
        if (lower == 'false') return 0;
        return int.tryParse(v) ?? 0;
      }

      return 0;
    }

    return PackingHeader(
      noBJ: json['NoBJ']?.toString() ?? '',
      dateCreate: json['DateCreate']?.toString() ?? '',
      idBJ: _toInt(json['IdBJ']),
      namaBJ: json['NamaBJ']?.toString(),
      pcs: _toDouble(json['Pcs']),
      berat: _toDouble(json['Berat']),
      isPartial: _toInt(json['IsPartial']),
      idWarehouse:
      json['IdWarehouse'] != null ? _toInt(json['IdWarehouse']) : null,
      blok: json['Blok']?.toString(),
      idLokasi: json['IdLokasi']?.toString(),
      outputType: json['OutputType']?.toString(),
      outputCode: json['OutputCode']?.toString(),
      outputNamaMesin: json['OutputNamaMesin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBJ': noBJ,
    'DateCreate': dateCreate,
    'IdBJ': idBJ,
    'NamaBJ': namaBJ,
    'Pcs': pcs,
    'Berat': berat,
    'IsPartial': isPartial,
    'IdWarehouse': idWarehouse,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'OutputType': outputType,
    'OutputCode': outputCode,
    'OutputNamaMesin': outputNamaMesin,
  };

  PackingHeader copyWith({
    String? noBJ,
    String? dateCreate,
    int? idBJ,
    String? namaBJ,
    double? pcs,
    double? berat,
    int? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? outputType,
    String? outputCode,
    String? outputNamaMesin,
  }) {
    return PackingHeader(
      noBJ: noBJ ?? this.noBJ,
      dateCreate: dateCreate ?? this.dateCreate,
      idBJ: idBJ ?? this.idBJ,
      namaBJ: namaBJ ?? this.namaBJ,
      pcs: pcs ?? this.pcs,
      berat: berat ?? this.berat,
      isPartial: isPartial ?? this.isPartial,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      outputType: outputType ?? this.outputType,
      outputCode: outputCode ?? this.outputCode,
      outputNamaMesin: outputNamaMesin ?? this.outputNamaMesin,
    );
  }
}
