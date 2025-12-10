// lib/features/furniture_wip/model/reject_header_model.dart

class FurnitureWipHeader {
  // Core
  final String noFurnitureWip;    // NoFurnitureWIP
  final String dateCreate;        // DateCreate (ISO/string dari API)
  final int idFurnitureWip;       // IdFurnitureWIP
  final String? namaFurnitureWip; // NamaFurnitureWIP (join MstCabinetWIP)

  /// Pcs di sini SUDAH dikurangi total partial
  /// sesuai logic di service (kalau IsPartial = 1).
  final double? pcs;

  /// Berat dari header (tidak dikurangi partial di service)
  final double? berat;

  final int isPartial;     // IsPartial (0 / 1)
  final int? idWarna;      // IdWarna
  final String? blok;      // Blok
  final String? idLokasi;  // IdLokasi (stringified)

  // 🔹 Info sumber produksi
  final String? outputType;       // 'HOTSTAMPING' / 'PASANG_KUNCI' / 'BONGKAR_SUSUN' / 'RETUR' / 'SPANNER' / 'INJECT'
  final String? outputCode;       // BH./BI./BG./L./BJ./S.******
  final String? outputNamaMesin;  // NamaMesin / 'Bongkar Susun' / NamaPembeli

  const FurnitureWipHeader({
    required this.noFurnitureWip,
    required this.dateCreate,
    required this.idFurnitureWip,
    this.namaFurnitureWip,
    this.pcs,
    this.berat,
    required this.isPartial,
    this.idWarna,
    this.blok,
    this.idLokasi,
    this.outputType,
    this.outputCode,
    this.outputNamaMesin,
  });

  // Convenience getters buat UI
  bool get isPartialBool => isPartial == 1;
  bool get hasLocation => (idLokasi ?? '').isNotEmpty;

  /// Label singkat untuk di table, kalau mau dipakai:
  /// contoh: "BH.000001 | MESIN 15"
  String get outputDisplay {
    if ((outputCode ?? '').isEmpty && (outputNamaMesin ?? '').isEmpty) {
      return '-';
    }
    if ((outputCode ?? '').isEmpty) return outputNamaMesin ?? '-';
    if ((outputNamaMesin ?? '').isEmpty) return outputCode ?? '-';
    return '$outputCode | $outputNamaMesin';
  }

  // ---- JSON helpers ----

  factory FurnitureWipHeader.fromJson(Map<String, dynamic> json) {
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

    return FurnitureWipHeader(
      noFurnitureWip: json['NoFurnitureWIP'] ?? '',
      dateCreate: json['DateCreate']?.toString() ?? '',
      idFurnitureWip: _toInt(json['IdFurnitureWIP']),
      namaFurnitureWip: json['NamaFurnitureWIP'],
      pcs: _toDouble(json['Pcs']),
      berat: _toDouble(json['Berat']),
      isPartial: _toInt(json['IsPartial']),
      idWarna: json['IdWarna'] != null ? _toInt(json['IdWarna']) : null,
      blok: json['Blok'],
      idLokasi: json['IdLokasi']?.toString(),

      // 🔹 mapping kolom baru dari API
      outputType: json['OutputType']?.toString(),
      outputCode: json['OutputCode']?.toString(),
      outputNamaMesin: json['OutputNamaMesin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoFurnitureWIP': noFurnitureWip,
    'DateCreate': dateCreate,
    'IdFurnitureWIP': idFurnitureWip,
    'NamaFurnitureWIP': namaFurnitureWip,
    'Pcs': pcs,
    'Berat': berat,
    'IsPartial': isPartial,
    'IdWarna': idWarna,
    'Blok': blok,
    'IdLokasi': idLokasi,

    'OutputType': outputType,
    'OutputCode': outputCode,
    'OutputNamaMesin': outputNamaMesin,
  };

  FurnitureWipHeader copyWith({
    String? noFurnitureWip,
    String? dateCreate,
    int? idFurnitureWip,
    String? namaFurnitureWip,
    double? pcs,
    double? berat,
    int? isPartial,
    int? idWarna,
    String? blok,
    String? idLokasi,
    String? outputType,
    String? outputCode,
    String? outputNamaMesin,
  }) {
    return FurnitureWipHeader(
      noFurnitureWip: noFurnitureWip ?? this.noFurnitureWip,
      dateCreate: dateCreate ?? this.dateCreate,
      idFurnitureWip: idFurnitureWip ?? this.idFurnitureWip,
      namaFurnitureWip: namaFurnitureWip ?? this.namaFurnitureWip,
      pcs: pcs ?? this.pcs,
      berat: berat ?? this.berat,
      isPartial: isPartial ?? this.isPartial,
      idWarna: idWarna ?? this.idWarna,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      outputType: outputType ?? this.outputType,
      outputCode: outputCode ?? this.outputCode,
      outputNamaMesin: outputNamaMesin ?? this.outputNamaMesin,
    );
  }
}
