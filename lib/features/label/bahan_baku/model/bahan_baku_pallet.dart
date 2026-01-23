// models/bahan_baku_pallet.dart

class BahanBakuPallet {
  final String noBahanBaku;
  final String noPallet;
  final int idJenisPlastik;
  final String namaJenisPlastik; // hasil join dari MstJenisPlastik.Jenis
  final int idWarehouse;
  final String namaWarehouse; // hasil join dari MstWarehouse.NamaWarehouse

  final String? keterangan;
  final int idStatus; // 0 = HOLD, 1 = PASS
  final String statusText; // "PASS" atau "HOLD"

  // ✅ pallet habis (semua detail sudah DateUsage terisi)
  final bool isEmpty; // IsEmpty

  // ✅ NEW: jumlah & berat (actual vs sisa)
  final int sakActual;     // SakActual
  final int sakSisa;       // SakSisa
  final double beratActual; // BeratActual
  final double beratSisa;   // BeratSisa

  // Quality Control fields (nullable karena bisa saja belum diisi)
  final double? moisture;
  final double? meltingIndex;
  final double? elasticity;
  final double? tenggelam;
  final double? density;
  final double? density2;
  final double? density3;

  final String? blok;
  final int? idLokasi;

  const BahanBakuPallet({
    required this.noBahanBaku,
    required this.noPallet,
    required this.idJenisPlastik,
    required this.namaJenisPlastik,
    required this.idWarehouse,
    required this.namaWarehouse,
    this.keterangan,
    required this.idStatus,
    required this.statusText,
    required this.isEmpty,

    // ✅ NEW
    required this.sakActual,
    required this.sakSisa,
    required this.beratActual,
    required this.beratSisa,

    this.moisture,
    this.meltingIndex,
    this.elasticity,
    this.tenggelam,
    this.density,
    this.density2,
    this.density3,
    this.blok,
    this.idLokasi,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _toBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
      if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
    }
    return defaultValue;
  }

  factory BahanBakuPallet.fromJson(Map<String, dynamic> json) {
    return BahanBakuPallet(
      noBahanBaku: json['NoBahanBaku']?.toString() ?? '',
      noPallet: json['NoPallet']?.toString() ?? '',
      idJenisPlastik: _toInt(json['IdJenisPlastik']),
      namaJenisPlastik: json['NamaJenisPlastik']?.toString() ?? '',
      idWarehouse: _toInt(json['IdWarehouse']),
      namaWarehouse: json['NamaWarehouse']?.toString() ?? '',

      keterangan: json['Keterangan']?.toString(),
      idStatus: _toInt(json['IdStatus']),
      statusText: json['StatusText']?.toString() ?? '',

      isEmpty: _toBool(json['IsEmpty'], defaultValue: false),

      // ✅ NEW
      sakActual: _toInt(json['SakActual']),
      sakSisa: _toInt(json['SakSisa']),
      beratActual: _toDouble(json['BeratActual']),
      beratSisa: _toDouble(json['BeratSisa']),

      moisture: _toDoubleOrNull(json['Moisture']),
      meltingIndex: _toDoubleOrNull(json['MeltingIndex']),
      elasticity: _toDoubleOrNull(json['Elasticity']),
      tenggelam: _toDoubleOrNull(json['Tenggelam']),
      density: _toDoubleOrNull(json['Density']),
      density2: _toDoubleOrNull(json['Density2']),
      density3: _toDoubleOrNull(json['Density3']),

      blok: json['Blok']?.toString(),
      idLokasi: json['IdLokasi'] != null ? _toInt(json['IdLokasi']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBahanBaku': noBahanBaku,
    'NoPallet': noPallet,
    'IdJenisPlastik': idJenisPlastik,
    'NamaJenisPlastik': namaJenisPlastik,
    'IdWarehouse': idWarehouse,
    'NamaWarehouse': namaWarehouse,
    'Keterangan': keterangan,
    'IdStatus': idStatus,
    'StatusText': statusText,

    'IsEmpty': isEmpty,

    // ✅ NEW
    'SakActual': sakActual,
    'SakSisa': sakSisa,
    'BeratActual': beratActual,
    'BeratSisa': beratSisa,

    'Moisture': moisture,
    'MeltingIndex': meltingIndex,
    'Elasticity': elasticity,
    'Tenggelam': tenggelam,
    'Density': density,
    'Density2': density2,
    'Density3': density3,
    'Blok': blok,
    'IdLokasi': idLokasi,
  };

  BahanBakuPallet copyWith({
    String? noBahanBaku,
    String? noPallet,
    int? idJenisPlastik,
    String? namaJenisPlastik,
    int? idWarehouse,
    String? namaWarehouse,
    String? keterangan,
    int? idStatus,
    String? statusText,
    bool? isEmpty,

    // ✅ NEW
    int? sakActual,
    int? sakSisa,
    double? beratActual,
    double? beratSisa,

    double? moisture,
    double? meltingIndex,
    double? elasticity,
    double? tenggelam,
    double? density,
    double? density2,
    double? density3,
    String? blok,
    int? idLokasi,
  }) {
    return BahanBakuPallet(
      noBahanBaku: noBahanBaku ?? this.noBahanBaku,
      noPallet: noPallet ?? this.noPallet,
      idJenisPlastik: idJenisPlastik ?? this.idJenisPlastik,
      namaJenisPlastik: namaJenisPlastik ?? this.namaJenisPlastik,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      namaWarehouse: namaWarehouse ?? this.namaWarehouse,
      keterangan: keterangan ?? this.keterangan,
      idStatus: idStatus ?? this.idStatus,
      statusText: statusText ?? this.statusText,
      isEmpty: isEmpty ?? this.isEmpty,

      // ✅ NEW
      sakActual: sakActual ?? this.sakActual,
      sakSisa: sakSisa ?? this.sakSisa,
      beratActual: beratActual ?? this.beratActual,
      beratSisa: beratSisa ?? this.beratSisa,

      moisture: moisture ?? this.moisture,
      meltingIndex: meltingIndex ?? this.meltingIndex,
      elasticity: elasticity ?? this.elasticity,
      tenggelam: tenggelam ?? this.tenggelam,
      density: density ?? this.density,
      density2: density2 ?? this.density2,
      density3: density3 ?? this.density3,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
    );
  }
}
