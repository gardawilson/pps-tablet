class StockOpnameLabel {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;
  final double berat;

  /// tambahan sesuai request
  final String? blok;     // e.g. "H2"
  final int? idLokasi;    // e.g. 12

  final String? username;

  StockOpnameLabel({
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    this.blok,
    this.idLokasi,
    this.username,
  });

  factory StockOpnameLabel.fromJson(Map<String, dynamic> json) {
    // normalisasi jmlhSak
    final dynamic sakRaw = json['jmlhSak'] ?? json['JmlhSak'] ?? json['Pcs'] ?? 0;
    final int jmlhSak = (sakRaw is int)
        ? sakRaw
        : int.tryParse(sakRaw.toString()) ?? 0;

    // normalisasi berat
    final dynamic beratRaw = json['berat'] ?? json['Berat'] ?? 0;
    final double berat = (beratRaw is num)
        ? beratRaw.toDouble()
        : double.tryParse(beratRaw.toString()) ?? 0.0;

    // normalisasi IdLokasi: boleh int/string/null → jadikan int?
    final dynamic idLokasiRaw = json['IdLokasi'] ?? json['idLokasi'] ?? json['idlokasi'];
    final int? idLokasi = (idLokasiRaw == null)
        ? null
        : (idLokasiRaw is int ? idLokasiRaw : int.tryParse(idLokasiRaw.toString()));

    // Blok bisa "Blok"/"blok"
    final String? blok = (json['Blok'] ?? json['blok'])?.toString();

    return StockOpnameLabel(
      nomorLabel: (json['nomorLabel'] ?? json['NomorLabel'] ?? '').toString(),
      labelType : (json['labelType']  ?? json['LabelType']  ?? '').toString(),
      jmlhSak   : jmlhSak,
      berat     : berat,
      blok      : blok,
      idLokasi  : idLokasi,
      username  : (json['username'] ?? json['Username'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NomorLabel': nomorLabel,
    'LabelType': labelType,
    'JmlhSak': jmlhSak,
    'Berat': berat,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'Username': username,
  };
}
