class WashingHeader {
  final String noWashing;
  final int idJenisPlastik;
  final String namaJenisPlastik;
  final int idWarehouse;
  final String namaWarehouse;
  final String dateCreate;
  final bool idStatus;          // ✅ boolean
  final String createBy;
  final String dateTimeCreate;
  final double? density;        // ✅ nullable
  final double? moisture;       // ✅ nullable

  WashingHeader({
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
  });

  factory WashingHeader.fromJson(Map<String, dynamic> json) {
    return WashingHeader(
      noWashing: json['NoWashing'] ?? '',
      idJenisPlastik: json['IdJenisPlastik'] ?? 0,
      namaJenisPlastik: json['NamaJenisPlastik'] ?? '',
      idWarehouse: json['IdWarehouse'] ?? 0,
      namaWarehouse: json['NamaWarehouse'] ?? '',
      dateCreate: json['DateCreate'] ?? '',
      idStatus: json['IdStatus'] == true,   // ✅ aman walau bool/null
      createBy: json['CreateBy'] ?? '',
      dateTimeCreate: json['DateTimeCreate'] ?? '',
      density: (json['Density'] as num?)?.toDouble() ?? 0.0,
      moisture: (json['Moisture'] as num?)?.toDouble() ?? 0.0,

    );
  }
}
