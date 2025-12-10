// lib/features/reject/model/reject_header_model.dart

class RejectHeader {
  // Core
  final String noReject;     // NoReject
  final String dateCreate;   // DateCreate (string apa adanya dari API)
  final int idReject;        // IdReject

  /// Berat dari header (di API sudah ISNULL(Berat, 0))
  final double? berat;

  final int isPartial;       // IsPartial (0 / 1)
  final int? idWarehouse;    // IdWarehouse (boleh null)
  final String? blok;        // Blok
  final String? idLokasi;    // IdLokasi (stringified)

  // Master reject
  final String? namaReject;  // NamaReject (dari MstReject)

  // 🔹 Info sumber produksi (INJECT / HOT_STAMPING / SPANNER / BJ_SORTIR)
  final String? outputType;       // 'INJECT' / 'HOT_STAMPING' / 'SPANNER' / 'BJ_SORTIR'
  final String? outputCode;       // NoProduksi / NoBJSortir
  final String? outputNamaMesin;  // NamaMesin / 'BJ Sortir'

  const RejectHeader({
    required this.noReject,
    required this.dateCreate,
    required this.idReject,
    this.berat,
    required this.isPartial,
    this.idWarehouse,
    this.blok,
    this.idLokasi,
    this.namaReject,
    this.outputType,
    this.outputCode,
    this.outputNamaMesin,
  });

  // ---------------------------------------------------------------------------
  // Convenience getters buat UI
  // ---------------------------------------------------------------------------

  bool get isPartialBool => isPartial == 1;
  bool get hasLocation => (idLokasi ?? '').isNotEmpty;

  String get namaRejectDisplay =>
      (namaReject == null || namaReject!.isEmpty) ? '-' : namaReject!;

  /// Label singkat untuk di table:
  /// contoh: "S.0000029950 | MESIN 280T" atau "BJ.0001 | BJ Sortir"
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

  factory RejectHeader.fromJson(Map<String, dynamic> json) {
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

    return RejectHeader(
      noReject: json['NoReject']?.toString() ?? '',
      dateCreate: json['DateCreate']?.toString() ?? '',
      idReject: _toInt(json['IdReject']),
      berat: _toDouble(json['Berat']),
      isPartial: _toInt(json['IsPartial']),
      idWarehouse:
      json['IdWarehouse'] != null ? _toInt(json['IdWarehouse']) : null,
      blok: json['Blok']?.toString(),
      idLokasi: json['IdLokasi']?.toString(),
      namaReject: json['NamaReject']?.toString(),
      outputType: json['OutputType']?.toString(),
      outputCode: json['OutputCode']?.toString(),
      outputNamaMesin: json['OutputNamaMesin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoReject': noReject,
    'DateCreate': dateCreate,
    'IdReject': idReject,
    'Berat': berat,
    'IsPartial': isPartial,
    'IdWarehouse': idWarehouse,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'NamaReject': namaReject,
    'OutputType': outputType,
    'OutputCode': outputCode,
    'OutputNamaMesin': outputNamaMesin,
  };

  RejectHeader copyWith({
    String? noReject,
    String? dateCreate,
    int? idReject,
    double? berat,
    int? isPartial,
    int? idWarehouse,
    String? blok,
    String? idLokasi,
    String? namaReject,
    String? outputType,
    String? outputCode,
    String? outputNamaMesin,
  }) {
    return RejectHeader(
      noReject: noReject ?? this.noReject,
      dateCreate: dateCreate ?? this.dateCreate,
      idReject: idReject ?? this.idReject,
      berat: berat ?? this.berat,
      isPartial: isPartial ?? this.isPartial,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      namaReject: namaReject ?? this.namaReject,
      outputType: outputType ?? this.outputType,
      outputCode: outputCode ?? this.outputCode,
      outputNamaMesin: outputNamaMesin ?? this.outputNamaMesin,
    );
  }
}
