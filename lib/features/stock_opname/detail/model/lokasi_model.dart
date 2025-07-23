class LokasiModel {
  final String idLokasi;
  final String blok;
  final bool enable;

  LokasiModel({
    required this.idLokasi,
    required this.blok,
    required this.enable,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      idLokasi: json['IdLokasi'] ?? '',
      blok: json['Blok'] ?? '',
      enable: json['Enable'] == 1,
    );
  }
}
