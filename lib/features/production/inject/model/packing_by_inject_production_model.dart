class PackingByInjectItem {
  final int idBJ;
  final String namaBJ;

  const PackingByInjectItem({
    required this.idBJ,
    required this.namaBJ,
  });

  factory PackingByInjectItem.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return PackingByInjectItem(
      idBJ: _toInt(j['IdBJ']),
      namaBJ: (j['NamaBJ'] as String?) ?? '',
    );
  }
}

/// Wrapper hasil API:
/// {
///   "success": true,
///   "data": {
///     "beratProdukHasilTimbang": 123.45,
///     "items": [ { IdBJ, NamaBJ }, ... ]
///   },
///   "meta": { ... }
/// }
class PackingByInjectResult {
  /// Sama seperti FurnitureWipByInjectResult: boleh null.
  final double? beratProdukHasilTimbang;
  final List<PackingByInjectItem> items;

  const PackingByInjectResult({
    required this.beratProdukHasilTimbang,
    required this.items,
  });

  factory PackingByInjectResult.fromEnvelope(
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
          (e) => PackingByInjectItem.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();

    return PackingByInjectResult(
      beratProdukHasilTimbang: berat,
      items: items,
    );
  }
}
