// Pastikan StockOpnameLabel.fromJson() bisa handle data dari socket
class StockOpnameLabel {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;
  final double berat;
  final String? idLokasi;
  final String? username;

  StockOpnameLabel({
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    this.idLokasi,
    this.username,
  });

  factory StockOpnameLabel.fromJson(Map<String, dynamic> json) {
    return StockOpnameLabel(
      nomorLabel: json['nomorLabel'] ?? json['NomorLabel'] ?? '', // ✅ Handle both cases
      labelType: json['labelType'] ?? json['LabelType'] ?? '',
      jmlhSak: (json['jmlhSak'] ?? json['JmlhSak'] ?? 0).toInt(),
      berat: (json['berat'] ?? json['Berat'] ?? 0.0).toDouble(),
      idLokasi: json['idLokasi'] ?? json['IdLokasi'] ?? json['idlokasi'],
      username: json['username'] ?? json['Username'],
    );
  }
}