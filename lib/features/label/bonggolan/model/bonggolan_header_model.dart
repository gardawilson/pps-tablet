// lib/features/bonggolan/model/reject_header_model.dart
class BonggolanHeader {
  // Core
  final String noBonggolan;       // NoBonggolan
  final String dateCreate;        // DateCreate (string/ISO from API)
  final int idBonggolan;          // IdBonggolan
  final String? namaBonggolan;    // NamaBonggolan (join MstBonggolan)
  final int idWarehouse;          // IdWarehouse
  final String? namaWarehouse;    // NamaWarehouse (join)
  final String? blok;             // Blok
  final String? idLokasi;         // IdLokasi (stringified)
  final double? berat;            // Berat
  final String statusText;        // PASS/HOLD

  // Outputs (Broker)
  final String? brokerNoProduksi;   // BrokerNoProduksi
  final String? brokerNamaMesin;    // BrokerNamaMesin

  // Outputs (Inject)
  final String? injectNoProduksi;   // InjectNoProduksi
  final String? injectNamaMesin;    // InjectNamaMesin

  // Bongkar Susun
  final String? noBongkarSusun;     // NoBongkarSusun

  const BonggolanHeader({
    required this.noBonggolan,
    required this.dateCreate,
    required this.idBonggolan,
    this.namaBonggolan,
    required this.idWarehouse,
    this.namaWarehouse,
    this.blok,
    this.idLokasi,
    this.berat,
    this.statusText = '',
    this.brokerNoProduksi,
    this.brokerNamaMesin,
    this.injectNoProduksi,
    this.injectNamaMesin,
    this.noBongkarSusun,
  });

  // Convenience: prefer Inject* then fallback to Broker*
  String? get refNoProduksi =>
      (injectNoProduksi != null && injectNoProduksi!.isNotEmpty)
          ? injectNoProduksi
          : (brokerNoProduksi != null && brokerNoProduksi!.isNotEmpty)
          ? brokerNoProduksi
          : null;

  String? get refNamaMesin =>
      (injectNamaMesin != null && injectNamaMesin!.isNotEmpty)
          ? injectNamaMesin
          : (brokerNamaMesin != null && brokerNamaMesin!.isNotEmpty)
          ? brokerNamaMesin
          : null;

  factory BonggolanHeader.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return BonggolanHeader(
      noBonggolan: json['NoBonggolan'] ?? '',
      dateCreate:  json['DateCreate'] ?? '',
      idBonggolan: _toInt(json['IdBonggolan']),
      namaBonggolan: json['NamaBonggolan'],
      idWarehouse: _toInt(json['IdWarehouse']),
      namaWarehouse: json['NamaWarehouse'],
      blok: json['Blok'],
      idLokasi: json['IdLokasi']?.toString(),
      berat: _toDouble(json['Berat']),
      statusText: (json['StatusText'] ?? '').toString(),
      brokerNoProduksi: json['BrokerNoProduksi'],
      brokerNamaMesin: json['BrokerNamaMesin'],
      injectNoProduksi: json['InjectNoProduksi'],
      injectNamaMesin: json['InjectNamaMesin'],
      noBongkarSusun: json['NoBongkarSusun'],
    );
  }

  Map<String, dynamic> toJson() => {
    'NoBonggolan': noBonggolan,
    'DateCreate': dateCreate,
    'IdBonggolan': idBonggolan,
    'NamaBonggolan': namaBonggolan,
    'IdWarehouse': idWarehouse,
    'NamaWarehouse': namaWarehouse,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'Berat': berat,
    'StatusText': statusText,
    'BrokerNoProduksi': brokerNoProduksi,
    'BrokerNamaMesin': brokerNamaMesin,
    'InjectNoProduksi': injectNoProduksi,
    'InjectNamaMesin': injectNamaMesin,
    'NoBongkarSusun': noBongkarSusun,
  };

  BonggolanHeader copyWith({
    String? noBonggolan,
    String? dateCreate,
    int? idBonggolan,
    String? namaBonggolan,
    int? idWarehouse,
    String? namaWarehouse,
    String? blok,
    String? idLokasi,
    double? berat,
    String? statusText,
    String? brokerNoProduksi,
    String? brokerNamaMesin,
    String? injectNoProduksi,
    String? injectNamaMesin,
    String? noBongkarSusun,
  }) {
    return BonggolanHeader(
      noBonggolan: noBonggolan ?? this.noBonggolan,
      dateCreate: dateCreate ?? this.dateCreate,
      idBonggolan: idBonggolan ?? this.idBonggolan,
      namaBonggolan: namaBonggolan ?? this.namaBonggolan,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      namaWarehouse: namaWarehouse ?? this.namaWarehouse,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      berat: berat ?? this.berat,
      statusText: statusText ?? this.statusText,
      brokerNoProduksi: brokerNoProduksi ?? this.brokerNoProduksi,
      brokerNamaMesin: brokerNamaMesin ?? this.brokerNamaMesin,
      injectNoProduksi: injectNoProduksi ?? this.injectNoProduksi,
      injectNamaMesin: injectNamaMesin ?? this.injectNamaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
    );
  }
}
