class PackingType {
  final int idBj;
  final String namaBj;
  final int idUom;
  final int? idBjType;
  final DateTime? tglSaldoAwal;
  final double beratStd;
  final bool enable;
  final String? itemCode;
  final double pcsPerLabel;
  final int? idTypeSubBarang;

  const PackingType({
    required this.idBj,
    required this.namaBj,
    required this.idUom,
    this.idBjType,
    this.tglSaldoAwal,
    required this.beratStd,
    required this.enable,
    this.itemCode,
    required this.pcsPerLabel,
    this.idTypeSubBarang,
  });

  // ==== helpers (sama gaya dengan FurnitureWipType) ====

  static int _toInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static double _toDouble(dynamic v, {double def = 0.0}) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      // handle "1,23" atau "1.23"
      final s = v.replaceAll(',', '.');
      return double.tryParse(s) ?? def;
    }
    return def;
  }

  static bool _toBool(dynamic v, {bool def = false}) {
    if (v == null) return def;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return def;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      if (v.isEmpty) return null;
      try {
        return DateTime.parse(v);
      } catch (_) {
        // fallback kalau BE kirim 'YYYY-MM-DD' saja
        try {
          return DateTime.parse('${v}T00:00:00');
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  // ==== JSON ====

  factory PackingType.fromJson(Map<String, dynamic> j) {
    final id = j['IdBJ'] ?? j['idBj'];
    final nama = j['NamaBJ'] ?? j['namaBj'] ?? '';

    final idUom = j['IdUOM'] ?? j['idUom'];
    final idBjType = j['IdBJType'] ?? j['idBjType'];
    final tglSaldo = j['TglSaldoAwal'] ?? j['tglSaldoAwal'];
    final beratStd = j['BeratSTD'] ?? j['beratStd'] ?? 0;
    final enable = j['Enable'] ?? j['enable'];
    final itemCode = j['ItemCode'] ?? j['itemCode'];
    final pcsLabel = j['PcsPerLabel'] ?? j['pcsPerLabel'] ?? 0;
    final idTypeSubBarang = j['IdTypeSubBarang'] ?? j['idTypeSubBarang'];

    return PackingType(
      idBj: _toInt(id),
      namaBj: nama.toString(),
      idUom: _toInt(idUom),
      idBjType: idBjType != null ? _toInt(idBjType) : null,
      tglSaldoAwal: _toDate(tglSaldo),
      beratStd: _toDouble(beratStd),
      enable: _toBool(enable, def: true),
      itemCode: itemCode?.toString(),
      pcsPerLabel: _toDouble(pcsLabel),
      idTypeSubBarang:
      idTypeSubBarang != null ? _toInt(idTypeSubBarang) : null,
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdBJ': idBj,
        'NamaBJ': namaBj,
        'IdUOM': idUom,
        'IdBJType': idBjType,
        'TglSaldoAwal': tglSaldoAwal?.toIso8601String(),
        'BeratSTD': beratStd,
        'Enable': enable,
        'ItemCode': itemCode,
        'PcsPerLabel': pcsPerLabel,
        'IdTypeSubBarang': idTypeSubBarang,
      };
    }
    return {
      'idBj': idBj,
      'namaBj': namaBj,
      'idUom': idUom,
      'idBjType': idBjType,
      'tglSaldoAwal': tglSaldoAwal?.toIso8601String(),
      'beratStd': beratStd,
      'enable': enable,
      'itemCode': itemCode,
      'pcsPerLabel': pcsPerLabel,
      'idTypeSubBarang': idTypeSubBarang,
    };
  }

  // ==== copyWith ====

  PackingType copyWith({
    int? idBj,
    String? namaBj,
    int? idUom,
    int? idBjType,
    DateTime? tglSaldoAwal,
    double? beratStd,
    bool? enable,
    String? itemCode,
    double? pcsPerLabel,
    int? idTypeSubBarang,
  }) {
    return PackingType(
      idBj: idBj ?? this.idBj,
      namaBj: namaBj ?? this.namaBj,
      idUom: idUom ?? this.idUom,
      idBjType: idBjType ?? this.idBjType,
      tglSaldoAwal: tglSaldoAwal ?? this.tglSaldoAwal,
      beratStd: beratStd ?? this.beratStd,
      enable: enable ?? this.enable,
      itemCode: itemCode ?? this.itemCode,
      pcsPerLabel: pcsPerLabel ?? this.pcsPerLabel,
      idTypeSubBarang: idTypeSubBarang ?? this.idTypeSubBarang,
    );
  }

  // ==== equality (by ID) ====

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PackingType && other.idBj == idBj;

  @override
  int get hashCode => idBj.hashCode;

  @override
  String toString() =>
      'PackingType(id: $idBj, nama: $namaBj, pcsPerLabel: $pcsPerLabel, enable: $enable)';
}
