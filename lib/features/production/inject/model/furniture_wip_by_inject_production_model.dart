/// Item Furniture WIP hasil mapping Inject:
/// 1 baris = 1 kandidat FurnitureWIP
/// { "IdFurnitureWIP": 1, "NamaFurnitureWIP": "CABINET XXX" }
class FurnitureWipByInjectItem {
  final int idFurnitureWip;
  final String namaFurnitureWip;

  const FurnitureWipByInjectItem({
    required this.idFurnitureWip,
    required this.namaFurnitureWip,
  });

  factory FurnitureWipByInjectItem.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return FurnitureWipByInjectItem(
      idFurnitureWip: _toInt(j['IdFurnitureWIP']),
      namaFurnitureWip: (j['NamaFurnitureWIP'] as String?) ?? '',
    );
  }
}

/// Wrapper hasil API:
/// {
///   "success": true,
///   "data": {
///     "beratProdukHasilTimbang": 123.45,
///     "items": [ { IdFurnitureWIP, NamaFurnitureWIP }, ... ]
///   },
///   "meta": { ... }
/// }
class FurnitureWipByInjectResult {
  /// BeratProdukHasilTimbang dari InjectProduksi_h
  /// Boleh null kalau backend kirim null.
  final double? beratProdukHasilTimbang;

  /// List kandidat FurnitureWIP (IdFurnitureWIP + NamaFurnitureWIP)
  final List<FurnitureWipByInjectItem> items;

  const FurnitureWipByInjectResult({
    required this.beratProdukHasilTimbang,
    required this.items,
  });

  /// Parse langsung dari envelope `body` full response:
  /// final result = FurnitureWipByInjectResult.fromEnvelope(body);
  factory FurnitureWipByInjectResult.fromEnvelope(
      Map<String, dynamic> envelope,
      ) {
    final data = (envelope['data'] as Map<String, dynamic>?) ?? const {};

    double? _toDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final double? berat =
    _toDoubleNullable(data['beratProdukHasilTimbang']);

    final List rawItems = (data['items'] as List?) ?? const [];

    final items = rawItems
        .map(
          (e) => FurnitureWipByInjectItem.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();

    return FurnitureWipByInjectResult(
      beratProdukHasilTimbang: berat,
      items: items,
    );
  }
}
