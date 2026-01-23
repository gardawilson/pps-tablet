class BahanBakuHeader {
  final String noBahanBaku;       // NoBahanBaku
  final int idSupplier;           // IdSupplier
  final String namaSupplier;      // NamaSupplier (hasil join MstSupplier.NmSupplier)

  final String? noPlat;           // NoPlat
  final String dateCreate;        // DateCreate

  // audit fields (optional)
  final String? createBy;         // CreateBy
  final String? dateTimeCreate;   // DateTimeCreate

  const BahanBakuHeader({
    required this.noBahanBaku,
    required this.idSupplier,
    required this.namaSupplier,
    this.noPlat,
    required this.dateCreate,
    this.createBy,
    this.dateTimeCreate,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory BahanBakuHeader.fromJson(Map<String, dynamic> json) {
    return BahanBakuHeader(
      noBahanBaku: json['NoBahanBaku']?.toString() ?? '',
      idSupplier: _toInt(json['IdSupplier']),
      namaSupplier: json['NamaSupplier']?.toString() ?? '',

      noPlat: json['NoPlat']?.toString(),
      dateCreate: json['DateCreate']?.toString() ?? '',

      createBy: json['CreateBy']?.toString(),
      dateTimeCreate: json['DateTimeCreate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBahanBaku': noBahanBaku,
    'IdSupplier': idSupplier,
    'NamaSupplier': namaSupplier,
    'NoPlat': noPlat,
    'DateCreate': dateCreate,
    'CreateBy': createBy,
    'DateTimeCreate': dateTimeCreate,
  };

  BahanBakuHeader copyWith({
    String? noBahanBaku,
    int? idSupplier,
    String? namaSupplier,
    String? noPlat,
    String? dateCreate,
    String? createBy,
    String? dateTimeCreate,
  }) {
    return BahanBakuHeader(
      noBahanBaku: noBahanBaku ?? this.noBahanBaku,
      idSupplier: idSupplier ?? this.idSupplier,
      namaSupplier: namaSupplier ?? this.namaSupplier,
      noPlat: noPlat ?? this.noPlat,
      dateCreate: dateCreate ?? this.dateCreate,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
    );
  }
}
