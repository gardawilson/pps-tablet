class WashingDetail {
  final String noWashing;
  final int noSak;
  final double? berat;
  final String? dateUsage;
  final String? idLokasi;

  WashingDetail({
    required this.noWashing,
    required this.noSak,
    this.berat,
    this.dateUsage,
    this.idLokasi,
  });

  factory WashingDetail.fromJson(Map<String, dynamic> json) {
    return WashingDetail(
      noWashing: json['NoWashing'] ?? '',
      noSak: json['NoSak'] ?? 0,
      berat: (json['Berat'] as num?)?.toDouble(),
      dateUsage: json['DateUsage'],
      idLokasi: json['IdLokasi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoWashing': noWashing,
      'NoSak': noSak,
      'Berat': berat,
      'DateUsage': dateUsage,
      'IdLokasi': idLokasi,
    };
  }
}
