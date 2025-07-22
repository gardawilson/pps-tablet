class StockOpnameLabelBeforeModel {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;
  final double berat;
  final String idLokasi;

  StockOpnameLabelBeforeModel({
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    required this.idLokasi,
  });

  factory StockOpnameLabelBeforeModel.fromJson(Map<String, dynamic> json) {
    return StockOpnameLabelBeforeModel(
      nomorLabel: json['NomorLabel']?.toString() ?? '',
      labelType: json['LabelType']?.toString() ?? '',
      jmlhSak: json['JmlhSak'] ?? 0,
      berat: (json['Berat'] ?? 0).toDouble(),
      idLokasi: json['IdLokasi']?.toString() ?? '-',
    );
  }
}
