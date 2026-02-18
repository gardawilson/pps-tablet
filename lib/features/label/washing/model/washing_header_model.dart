class WashingHeader {
  final String noWashing;
  final int idJenisPlastik;
  final String namaJenisPlastik;
  final int? idWarehouse;
  final String? namaWarehouse;
  final String dateCreate;
  final bool? idStatus;
  final String? statusText;
  final String createBy;
  final String dateTimeCreate;
  final double? density;
  final double? density2;
  final double? density3;
  final double? moisture;
  final double? moisture2;
  final double? moisture3;

  // ➕ field tambahan dari join
  final String? noProduksi;
  final String? namaMesin;
  final String? noBongkarSusun;

  // 🆕 field baru dari header langsung
  final String? blok;
  final int? idLokasi;

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
    this.statusText,
    this.density,
    this.density2,
    this.density3,
    this.moisture,
    this.moisture2,
    this.moisture3,
    this.noProduksi,
    this.namaMesin,
    this.noBongkarSusun,
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
      statusText: json['StatusText'],
      createBy: json['CreateBy'] ?? '',
      dateTimeCreate: json['DateTimeCreate'] ?? '',
      density: (json['Density'] as num?)?.toDouble(),
      density2: (json['Density2'] as num?)?.toDouble(),
      density3: (json['Density3'] as num?)?.toDouble(),
      moisture: (json['Moisture'] as num?)?.toDouble(),
      moisture2: (json['Moisture2'] as num?)?.toDouble(),
      moisture3: (json['Moisture3'] as num?)?.toDouble(),
      noProduksi: json['NoProduksi'],
      namaMesin: json['NamaMesin'],
      noBongkarSusun: json['NoBongkarSusun'],
      blok: json['Blok'],
      idLokasi: (json['IdLokasi'] as num?)?.toInt(),
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
    'StatusText': statusText,
    'CreateBy': createBy,
    'DateTimeCreate': dateTimeCreate,
    'Density': density,
    'Density2': density2,
    'Density3': density3,
    'Moisture': moisture,
    'Moisture2': moisture2,
    'Moisture3': moisture3,
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
    String? statusText,
    String? createBy,
    String? dateTimeCreate,
    double? density,
    double? density2,
    double? density3,
    double? moisture,
    double? moisture2,
    double? moisture3,
    String? noProduksi,
    String? namaMesin,
    String? noBongkarSusun,
    String? blok,
    int? idLokasi,
  }) {
    return WashingHeader(
      noWashing: noWashing ?? this.noWashing,
      idJenisPlastik: idJenisPlastik ?? this.idJenisPlastik,
      namaJenisPlastik: namaJenisPlastik ?? this.namaJenisPlastik,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      namaWarehouse: namaWarehouse ?? this.namaWarehouse,
      dateCreate: dateCreate ?? this.dateCreate,
      idStatus: idStatus ?? this.idStatus,
      statusText: statusText ?? this.statusText,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
      density: density ?? this.density,
      density2: density2 ?? this.density2,
      density3: density3 ?? this.density3,
      moisture: moisture ?? this.moisture,
      moisture2: moisture2 ?? this.moisture2,
      moisture3: moisture3 ?? this.moisture3,
      noProduksi: noProduksi ?? this.noProduksi,
      namaMesin: namaMesin ?? this.namaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
    );
  }
}
