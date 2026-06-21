class MappingBlok {
  final String blok;
  final int idWarehouse;
  final String namaWarehouse;
  final int totalLokasi;
  final int totalJenis;

  MappingBlok({
    required this.blok,
    required this.idWarehouse,
    required this.namaWarehouse,
    this.totalLokasi = 0,
    this.totalJenis = 0,
  });

  factory MappingBlok.fromJson(Map<String, dynamic> json) {
    final rawId = json['IdWarehouse'];
    return MappingBlok(
      blok: (json['Blok'] ?? '').toString(),
      idWarehouse: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      namaWarehouse: (json['NamaWarehouse'] ?? '').toString(),
      totalLokasi: (json['TotalLokasi'] as num?)?.toInt() ?? 0,
      totalJenis: (json['TotalJenis'] as num?)?.toInt() ?? 0,
    );
  }
}
