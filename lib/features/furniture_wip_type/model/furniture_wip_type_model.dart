class FurnitureWipType {
  final int idCabinetWip;
  final String nama;
  final int idCabinetWipType;
  final double saldoAwal;
  final DateTime? tglSaldoAwal;
  final int idUom;
  final bool enable;
  final int? idTypeFurnitureWip;
  final int? idFurnitureCategory;
  final double pcsPerLabel;
  final bool isInputInjectProduksi;
  final int? idWarna;

  const FurnitureWipType({
    required this.idCabinetWip,
    required this.nama,
    required this.idCabinetWipType,
    required this.saldoAwal,
    required this.tglSaldoAwal,
    required this.idUom,
    required this.enable,
    this.idTypeFurnitureWip,
    this.idFurnitureCategory,
    required this.pcsPerLabel,
    required this.isInputInjectProduksi,
    this.idWarna,
  });

  // ==== helpers ====

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

  factory FurnitureWipType.fromJson(Map<String, dynamic> j) {
    final id = j['IdCabinetWIP'] ?? j['idCabinetWip'];
    final nama = j['Nama'] ?? j['nama'] ?? '';

    final idCabinetType = j['IdCabinetWIPType'] ?? j['idCabinetWipType'];
    final saldo = j['SaldoAwal'] ?? j['saldoAwal'] ?? 0;
    final tglSaldo = j['TglSaldoAwal'] ?? j['tglSaldoAwal'];
    final idUom = j['IdUOM'] ?? j['idUom'];
    final enable = j['Enable'] ?? j['enable'];

    final idTypeFwip = j['IdTypeFurnitureWIP'] ?? j['idTypeFurnitureWip'];
    final idCategory = j['IdFurnitureCategory'] ?? j['idFurnitureCategory'];
    final pcsLabel = j['PcsPerLabel'] ?? j['pcsPerLabel'] ?? 0;
    final isInputInject =
        j['IsInputInjectProduksi'] ?? j['isInputInjectProduksi'] ?? 0;
    final idWarna = j['IdWarna'] ?? j['idWarna'];

    return FurnitureWipType(
      idCabinetWip: _toInt(id),
      nama: nama.toString(),
      idCabinetWipType: _toInt(idCabinetType),
      saldoAwal: _toDouble(saldo),
      tglSaldoAwal: _toDate(tglSaldo),
      idUom: _toInt(idUom),
      enable: _toBool(enable, def: true),
      idTypeFurnitureWip: idTypeFwip != null ? _toInt(idTypeFwip) : null,
      idFurnitureCategory: idCategory != null ? _toInt(idCategory) : null,
      pcsPerLabel: _toDouble(pcsLabel),
      isInputInjectProduksi: _toBool(isInputInject),
      idWarna: idWarna != null ? _toInt(idWarna) : null,
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdCabinetWIP': idCabinetWip,
        'Nama': nama,
        'IdCabinetWIPType': idCabinetWipType,
        'SaldoAwal': saldoAwal,
        'TglSaldoAwal': tglSaldoAwal?.toIso8601String(),
        'IdUOM': idUom,
        'Enable': enable,
        'IdTypeFurnitureWIP': idTypeFurnitureWip,
        'IdFurnitureCategory': idFurnitureCategory,
        'PcsPerLabel': pcsPerLabel,
        'IsInputInjectProduksi': isInputInjectProduksi,
        'IdWarna': idWarna,
      };
    }
    return {
      'idCabinetWip': idCabinetWip,
      'nama': nama,
      'idCabinetWipType': idCabinetWipType,
      'saldoAwal': saldoAwal,
      'tglSaldoAwal': tglSaldoAwal?.toIso8601String(),
      'idUom': idUom,
      'enable': enable,
      'idTypeFurnitureWip': idTypeFurnitureWip,
      'idFurnitureCategory': idFurnitureCategory,
      'pcsPerLabel': pcsPerLabel,
      'isInputInjectProduksi': isInputInjectProduksi,
      'idWarna': idWarna,
    };
  }

  // ==== copyWith ====

  FurnitureWipType copyWith({
    int? idCabinetWip,
    String? nama,
    int? idCabinetWipType,
    double? saldoAwal,
    DateTime? tglSaldoAwal,
    int? idUom,
    bool? enable,
    int? idTypeFurnitureWip,
    int? idFurnitureCategory,
    double? pcsPerLabel,
    bool? isInputInjectProduksi,
    int? idWarna,
  }) {
    return FurnitureWipType(
      idCabinetWip: idCabinetWip ?? this.idCabinetWip,
      nama: nama ?? this.nama,
      idCabinetWipType: idCabinetWipType ?? this.idCabinetWipType,
      saldoAwal: saldoAwal ?? this.saldoAwal,
      tglSaldoAwal: tglSaldoAwal ?? this.tglSaldoAwal,
      idUom: idUom ?? this.idUom,
      enable: enable ?? this.enable,
      idTypeFurnitureWip: idTypeFurnitureWip ?? this.idTypeFurnitureWip,
      idFurnitureCategory:
      idFurnitureCategory ?? this.idFurnitureCategory,
      pcsPerLabel: pcsPerLabel ?? this.pcsPerLabel,
      isInputInjectProduksi:
      isInputInjectProduksi ?? this.isInputInjectProduksi,
      idWarna: idWarna ?? this.idWarna,
    );
  }

  // ==== equality (by ID) ====

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FurnitureWipType && other.idCabinetWip == idCabinetWip;

  @override
  int get hashCode => idCabinetWip.hashCode;

  @override
  String toString() =>
      'FurnitureWipType(id: $idCabinetWip, nama: $nama, pcsPerLabel: $pcsPerLabel, enable: $enable)';
}
