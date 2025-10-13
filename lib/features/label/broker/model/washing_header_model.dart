class WashingHeader {
  final String noWashing;
  final int idJenisPlastik;
  final String namaJenisPlastik;
  final int idWarehouse;
  final String namaWarehouse;
  final String dateCreate;
  final bool? idStatus;
  final String createBy;
  final String dateTimeCreate;
  final double? density;
  final double? moisture;

  // ➕ field tambahan dari join
  final String? noProduksi;
  final String namaMesin;
  final String? noBongkarSusun;

  // 🆕 field baru dari header langsung
  final String? blok;
  final String? idLokasi;

  const WashingHeader({
    required this.noWashing,
    required this.idJenisPlastik,
    required this.namaJenisPlastik,
    required this.idWarehouse,
    required this.namaWarehouse,
    required this.dateCreate,
    required this.idStatus,
    required this.createBy,
    required this.dateTimeCreate,
    this.density,
    this.moisture,
    this.noProduksi = '',
    this.namaMesin = '',
    this.noBongkarSusun = '',
    this.blok,
    this.idLokasi,
  });

  // Converter boolean yang robust
  static bool _toBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return defaultValue;
  }

  factory WashingHeader.fromJson(Map<String, dynamic> json) {
    return WashingHeader(
      noWashing: json['NoWashing'] ?? '',
      idJenisPlastik: (json['IdJenisPlastik'] is String)
          ? int.tryParse(json['IdJenisPlastik']) ?? 0
          : (json['IdJenisPlastik'] as num?)?.toInt() ?? 0,
      namaJenisPlastik: json['NamaJenisPlastik'] ?? '',
      idWarehouse: (json['IdWarehouse'] is String)
          ? int.tryParse(json['IdWarehouse']) ?? 0
          : (json['IdWarehouse'] as num?)?.toInt() ?? 0,
      namaWarehouse: json['NamaWarehouse'] ?? '',
      dateCreate: json['DateCreate'] ?? '',
      idStatus: _toBool(json['IdStatus']),
      createBy: json['CreateBy'] ?? '',
      dateTimeCreate: json['DateTimeCreate'] ?? '',
      density: (json['Density'] as num?)?.toDouble(),
      moisture: (json['Moisture'] as num?)?.toDouble(),
      noProduksi: json['NoProduksi'] ?? '',
      namaMesin: json['NamaMesin'] ?? '',
      noBongkarSusun: json['NoBongkarSusun'] ?? '',
      blok: json['Blok'] ?? '',
      idLokasi: json['IdLokasi']?.toString() ?? '', // bisa string atau int dari server
    );
  }

  Map<String, dynamic> toJson() => {
    'NoWashing': noWashing,
    'IdJenisPlastik': idJenisPlastik,
    'NamaJenisPlastik': namaJenisPlastik,
    'IdWarehouse': idWarehouse,
    'NamaWarehouse': namaWarehouse,
    'DateCreate': dateCreate,
    'IdStatus': idStatus,
    'CreateBy': createBy,
    'DateTimeCreate': dateTimeCreate,
    'Density': density,
    'Moisture': moisture,
    'NoProduksi': noProduksi,
    'NamaMesin': namaMesin,
    'NoBongkarSusun': noBongkarSusun,
    'Blok': blok,
    'IdLokasi': idLokasi,
  };

  WashingHeader copyWith({
    String? noWashing,
    int? idJenisPlastik,
    String? namaJenisPlastik,
    int? idWarehouse,
    String? namaWarehouse,
    String? dateCreate,
    bool? idStatus,
    String? createBy,
    String? dateTimeCreate,
    double? density,
    double? moisture,
    String? noProduksi,
    String? namaMesin,
    String? noBongkarSusun,
    String? blok,
    String? idLokasi,
  }) {
    return WashingHeader(
      noWashing: noWashing ?? this.noWashing,
      idJenisPlastik: idJenisPlastik ?? this.idJenisPlastik,
      namaJenisPlastik: namaJenisPlastik ?? this.namaJenisPlastik,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      namaWarehouse: namaWarehouse ?? this.namaWarehouse,
      dateCreate: dateCreate ?? this.dateCreate,
      idStatus: idStatus ?? this.idStatus,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
      density: density ?? this.density,
      moisture: moisture ?? this.moisture,
      noProduksi: noProduksi ?? this.noProduksi,
      namaMesin: namaMesin ?? this.namaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
    );
  }
}
