class MappingBlok {
  final String blok;
  final int idWarehouse;
  final String namaWarehouse;

  MappingBlok({
    required this.blok,
    required this.idWarehouse,
    required this.namaWarehouse,
  });

  factory MappingBlok.fromJson(Map<String, dynamic> json) {
    final rawId = json['IdWarehouse'];
    return MappingBlok(
      blok: (json['Blok'] ?? '').toString(),
      idWarehouse: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      namaWarehouse: (json['NamaWarehouse'] ?? '').toString(),
    );
  }
}
