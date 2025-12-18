class StockOpname {
  final String noSO;
  final String tanggal;
  final String namaWarehouse;

  /// Dari API: "28, 27, 26, ..."
  /// Kita parse jadi list int: [28, 27, 26, ...]
  final List<int> idWarehouses;

  final bool isBahanBaku;
  final bool isWashing;
  final bool isBonggolan;
  final bool isCrusher;
  final bool isBroker;
  final bool isGilingan;
  final bool isMixer;
  final bool isFurnitureWIP;
  final bool isBarangJadi;
  final bool isReject;
  final bool isAscend;

  StockOpname({
    required this.noSO,
    required this.tanggal,
    required this.namaWarehouse,
    required this.idWarehouses,
    required this.isBahanBaku,
    required this.isWashing,
    required this.isBonggolan,
    required this.isCrusher,
    required this.isBroker,
    required this.isGilingan,
    required this.isMixer,
    required this.isFurnitureWIP,
    required this.isBarangJadi,
    required this.isReject,
    required this.isAscend,
  });

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return false;
  }

  static List<int> _parseIdWarehouses(dynamic v) {
    if (v == null) return <int>[];

    // kalau backend suatu saat kirim int tunggal
    if (v is int) return <int>[v];

    // kalau backend suatu saat kirim list
    if (v is List) {
      return v
          .map((e) => int.tryParse(e.toString().trim()))
          .whereType<int>()
          .toList();
    }

    // default: string "28, 27, 26"
    final s = v.toString().trim();
    if (s.isEmpty) return <int>[];

    return s
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      noSO: (json['NoSO'] ?? '').toString(),
      tanggal: (json['Tanggal'] ?? '').toString(),
      namaWarehouse: (json['NamaWarehouse'] ?? '-').toString(),
      idWarehouses: _parseIdWarehouses(json['IdWarehouse']),

      isBahanBaku: _asBool(json['IsBahanBaku']),
      isWashing: _asBool(json['IsWashing']),
      isBonggolan: _asBool(json['IsBonggolan']),
      isCrusher: _asBool(json['IsCrusher']),
      isBroker: _asBool(json['IsBroker']),
      isGilingan: _asBool(json['IsGilingan']),
      isMixer: _asBool(json['IsMixer']),
      isFurnitureWIP: _asBool(json['IsFurnitureWIP']),
      isBarangJadi: _asBool(json['IsBarangJadi']),
      isReject: _asBool(json['IsReject']),
      isAscend: _asBool(json['IsAscend']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoSO': noSO,
      'Tanggal': tanggal,
      'NamaWarehouse': namaWarehouse,
      // simpan balik sebagai string biar sama format API (opsional)
      'IdWarehouse': idWarehouses.join(', '),
      'IsBahanBaku': isBahanBaku,
      'IsWashing': isWashing,
      'IsBonggolan': isBonggolan,
      'IsCrusher': isCrusher,
      'IsBroker': isBroker,
      'IsGilingan': isGilingan,
      'IsMixer': isMixer,
      'IsFurnitureWIP': isFurnitureWIP,
      'IsBarangJadi': isBarangJadi,
      'IsReject': isReject,
      'IsAscend': isAscend,
    };
  }
}
