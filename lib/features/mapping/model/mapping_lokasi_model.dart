class MappingLokasi {
  final int idLokasi;
  final String blok;
  final String description;
  final bool enable;
  final String label;

  MappingLokasi({
    required this.idLokasi,
    required this.blok,
    required this.description,
    required this.enable,
    required this.label,
  });

  factory MappingLokasi.fromJson(Map<String, dynamic> json) {
    final rawId = json['IdLokasi'];
    final rawEnable = json['Enable'];

    return MappingLokasi(
      idLokasi: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      blok: (json['Blok'] ?? '').toString(),
      description: (json['Description'] ?? '').toString(),
      enable: rawEnable is bool
          ? rawEnable
          : rawEnable?.toString().toLowerCase() == 'true',
      label: (json['label'] ?? '').toString(),
    );
  }
}
