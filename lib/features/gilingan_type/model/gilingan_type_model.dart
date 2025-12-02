class GilinganType {
  final int idGilingan;
  final String namaGilingan;
  final double saldoAwal;
  final bool enable; // backend returns only active, but keep for completeness

  const GilinganType({
    required this.idGilingan,
    required this.namaGilingan,
    required this.saldoAwal,
    required this.enable,
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
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? def;
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

  // ==== JSON ====
  factory GilinganType.fromJson(Map<String, dynamic> j) {
    final id = j['IdGilingan'] ?? j['idGilingan'];
    final nama = j['NamaGilingan'] ?? j['namaGilingan'] ?? '';
    final saldo = j['SaldoAwal'] ?? j['saldoAwal'] ?? 0;
    final enable = j['Enable'] ?? j['enable'];

    return GilinganType(
      idGilingan: _toInt(id),
      namaGilingan: nama.toString(),
      saldoAwal: _toDouble(saldo),
      enable: _toBool(enable, def: true),
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdGilingan': idGilingan,
        'NamaGilingan': namaGilingan,
        'SaldoAwal': saldoAwal,
        'Enable': enable,
      };
    }
    return {
      'idGilingan': idGilingan,
      'namaGilingan': namaGilingan,
      'saldoAwal': saldoAwal,
      'enable': enable,
    };
  }

  // ==== copyWith ====
  GilinganType copyWith({
    int? idGilingan,
    String? namaGilingan,
    double? saldoAwal,
    bool? enable,
  }) {
    return GilinganType(
      idGilingan: idGilingan ?? this.idGilingan,
      namaGilingan: namaGilingan ?? this.namaGilingan,
      saldoAwal: saldoAwal ?? this.saldoAwal,
      enable: enable ?? this.enable,
    );
  }

  // ==== equality (by ID) ====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GilinganType && other.idGilingan == idGilingan;

  @override
  int get hashCode => idGilingan.hashCode;

  @override
  String toString() =>
      'GilinganType(id: $idGilingan, nama: $namaGilingan, saldoAwal: $saldoAwal, enable: $enable)';
}
