// lib/features/crusher/model/reject_header_model.dart
class CrusherHeader {
  // Core
  final String noCrusher;        // NoCrusher
  final String dateCreate;       // DateCreate (ISO/string from API)
  final int idCrusher;           // IdCrusher
  final String? namaCrusher;     // NamaCrusher (join MstCrusher)
  final int idWarehouse;         // IdWarehouse
  final String? namaWarehouse;   // NamaWarehouse (join)
  final String? blok;            // Blok
  final String? idLokasi;        // IdLokasi (stringified)
  final double? berat;           // Berat
  final String statusText;       // PASS/HOLD

  // New joins
  final String? crusherNoProduksi; // from CrusherProduksiOutput.NoCrusherProduksi
  final String? crusherNamaMesin;  // from MstMesin.NamaMesin via CrusherProduksi_h
  final String? noBongkarSusun;    // from BongkarSusunOutputCrusher.NoBongkarSusun

  const CrusherHeader({
    required this.noCrusher,
    required this.dateCreate,
    required this.idCrusher,
    this.namaCrusher,
    required this.idWarehouse,
    this.namaWarehouse,
    this.blok,
    this.idLokasi,
    this.berat,
    this.statusText = '',
    this.crusherNoProduksi,
    this.crusherNamaMesin,
    this.noBongkarSusun,
  });

  // Optional convenience (e.g., for a unified “ref” display)
  String? get refNoProduksi => crusherNoProduksi;
  String? get refNamaMesin  => crusherNamaMesin;

  factory CrusherHeader.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CrusherHeader(
      noCrusher: json['NoCrusher'] ?? '',
      dateCreate: json['DateCreate'] ?? '',
      idCrusher: _toInt(json['IdCrusher']),
      namaCrusher: json['NamaCrusher'],
      idWarehouse: _toInt(json['IdWarehouse']),
      namaWarehouse: json['NamaWarehouse'],
      blok: json['Blok'],
      idLokasi: json['IdLokasi']?.toString(),
      berat: _toDouble(json['Berat']),
      statusText: (json['StatusText'] ?? '').toString(),

      // NEW mappings
      crusherNoProduksi: json['CrusherNoProduksi'],
      crusherNamaMesin: json['CrusherNamaMesin'],
      noBongkarSusun: json['NoBongkarSusun'],
    );
  }

  Map<String, dynamic> toJson() => {
    'NoCrusher': noCrusher,
    'DateCreate': dateCreate,
    'IdCrusher': idCrusher,
    'NamaCrusher': namaCrusher,
    'IdWarehouse': idWarehouse,
    'NamaWarehouse': namaWarehouse,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'Berat': berat,
    'StatusText': statusText,

    // NEW serializations
    'CrusherNoProduksi': crusherNoProduksi,
    'CrusherNamaMesin': crusherNamaMesin,
    'NoBongkarSusun': noBongkarSusun,
  };

  CrusherHeader copyWith({
    String? noCrusher,
    String? dateCreate,
    int? idCrusher,
    String? namaCrusher,
    int? idWarehouse,
    String? namaWarehouse,
    String? blok,
    String? idLokasi,
    double? berat,
    String? statusText,
    String? crusherNoProduksi,
    String? crusherNamaMesin,
    String? noBongkarSusun,
  }) {
    return CrusherHeader(
      noCrusher: noCrusher ?? this.noCrusher,
      dateCreate: dateCreate ?? this.dateCreate,
      idCrusher: idCrusher ?? this.idCrusher,
      namaCrusher: namaCrusher ?? this.namaCrusher,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      namaWarehouse: namaWarehouse ?? this.namaWarehouse,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      berat: berat ?? this.berat,
      statusText: statusText ?? this.statusText,
      crusherNoProduksi: crusherNoProduksi ?? this.crusherNoProduksi,
      crusherNamaMesin: crusherNamaMesin ?? this.crusherNamaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
    );
  }
}
