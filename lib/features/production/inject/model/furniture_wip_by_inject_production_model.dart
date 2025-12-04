class FurnitureWipByInjectProduction {
  final int idFurnitureWip;
  final String namaFurnitureWip;

  FurnitureWipByInjectProduction({
    required this.idFurnitureWip,
    required this.namaFurnitureWip,
  });

  factory FurnitureWipByInjectProduction.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return FurnitureWipByInjectProduction(
      idFurnitureWip: _toInt(j['IdFurnitureWIP']),
      namaFurnitureWip: (j['NamaFurnitureWIP'] as String?) ?? '',
    );
  }
}
