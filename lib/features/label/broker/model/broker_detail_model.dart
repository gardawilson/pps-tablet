class BrokerDetail {
  final String noBroker;        // NoBroker
  final int noSak;              // NoSak
  final double? berat;          // Berat
  final String? dateUsage;      // DateUsage (already formatted by API)
  final String? idLokasi;       // IdLokasi (stringify to be safe)
  final bool? isPartial;        // IsPartial

  const BrokerDetail({
    required this.noBroker,
    required this.noSak,
    this.berat,
    this.dateUsage,
    this.idLokasi,
    this.isPartial,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'y' || s == 'yes';
    }
    return null;
  }

  factory BrokerDetail.fromJson(Map<String, dynamic> json) {
    return BrokerDetail(
      noBroker: json['NoBroker']?.toString() ?? '',
      noSak: _toInt(json['NoSak']),
      berat: _toDouble(json['Berat']),
      dateUsage: json['DateUsage']?.toString(),
      idLokasi: json['IdLokasi']?.toString(),
      isPartial: _toBool(json['IsPartial']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoBroker': noBroker,
      'NoSak': noSak,
      'Berat': berat,
      'DateUsage': dateUsage,
      'IdLokasi': idLokasi,
      'IsPartial': isPartial,
    };
  }
}
