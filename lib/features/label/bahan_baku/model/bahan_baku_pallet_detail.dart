// models/bahan_baku_pallet_detail.dart

class BahanBakuPalletDetail {
  final String noBahanBaku;
  final String noPallet;
  final String noSak;
  final String? timeCreate;       // TIME field dari SQL

  final double berat;             // Sudah dikurangi partial di query
  final double? beratAct;         // BeratAct (optional)
  final String? dateUsage;        // DateUsage (sudah diformat di backend)

  final int isLembab;             // 0 atau 1
  final int isPartial;            // 0 atau 1
  final int? idLokasi;

  const BahanBakuPalletDetail({
    required this.noBahanBaku,
    required this.noPallet,
    required this.noSak,
    this.timeCreate,
    required this.berat,
    this.beratAct,
    this.dateUsage,
    required this.isLembab,
    required this.isPartial,
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

  factory BahanBakuPalletDetail.fromJson(Map<String, dynamic> json) {
    return BahanBakuPalletDetail(
      noBahanBaku: json['NoBahanBaku']?.toString() ?? '',
      noPallet: json['NoPallet']?.toString() ?? '',
      noSak: json['NoSak']?.toString() ?? '',
      timeCreate: json['TimeCreate']?.toString(),

      berat: _toDouble(json['Berat']),
      beratAct: _toDoubleOrNull(json['BeratAct']),
      dateUsage: json['DateUsage']?.toString(),

      isLembab: _toInt(json['IsLembab']),
      isPartial: _toInt(json['IsPartial']),
      idLokasi: json['IdLokasi'] != null ? _toInt(json['IdLokasi']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBahanBaku': noBahanBaku,
    'NoPallet': noPallet,
    'NoSak': noSak,
    'TimeCreate': timeCreate,
    'Berat': berat,
    'BeratAct': beratAct,
    'DateUsage': dateUsage,
    'IsLembab': isLembab,
    'IsPartial': isPartial,
    'IdLokasi': idLokasi,
  };

  BahanBakuPalletDetail copyWith({
    String? noBahanBaku,
    String? noPallet,
    String? noSak,
    String? timeCreate,
    double? berat,
    double? beratAct,
    String? dateUsage,
    int? isLembab,
    int? isPartial,
    int? idLokasi,
  }) {
    return BahanBakuPalletDetail(
      noBahanBaku: noBahanBaku ?? this.noBahanBaku,
      noPallet: noPallet ?? this.noPallet,
      noSak: noSak ?? this.noSak,
      timeCreate: timeCreate ?? this.timeCreate,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      dateUsage: dateUsage ?? this.dateUsage,
      isLembab: isLembab ?? this.isLembab,
      isPartial: isPartial ?? this.isPartial,
      idLokasi: idLokasi ?? this.idLokasi,
    );
  }

  // Helper getters untuk kemudahan UI
  bool get isUsed => dateUsage != null && dateUsage!.isNotEmpty;
  bool get isPartiallyUsed => isPartial == 1;
  bool get isWet => isLembab == 1;
}