class RejectType {
  final int idReject;
  final String namaReject;
  final double saldoAwal;
  final bool enable;
  final DateTime? tglSaldoAwal;
  final String? itemCode;

  const RejectType({
    required this.idReject,
    required this.namaReject,
    required this.saldoAwal,
    required this.enable,
    this.tglSaldoAwal,
    this.itemCode,
  });

  // ==== helpers (sama gaya dengan PackingType) ====

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

  factory RejectType.fromJson(Map<String, dynamic> j) {
    final id = j['IdReject'] ?? j['idReject'];
    final nama = j['NamaReject'] ?? j['namaReject'] ?? '';

    final saldoAwal = j['SaldoAwal'] ?? j['saldoAwal'] ?? 0;
    final enable = j['Enable'] ?? j['enable'];
    final tglSaldo = j['TglSaldoAwal'] ?? j['tglSaldoAwal'];
    final itemCode = j['ItemCode'] ?? j['itemCode'];

    return RejectType(
      idReject: _toInt(id),
      namaReject: nama.toString(),
      saldoAwal: _toDouble(saldoAwal),
      enable: _toBool(enable, def: true),
      tglSaldoAwal: _toDate(tglSaldo),
      itemCode: itemCode?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdReject': idReject,
        'NamaReject': namaReject,
        'SaldoAwal': saldoAwal,
        'Enable': enable,
        'TglSaldoAwal': tglSaldoAwal?.toIso8601String(),
        'ItemCode': itemCode,
      };
    }
    return {
      'idReject': idReject,
      'namaReject': namaReject,
      'saldoAwal': saldoAwal,
      'enable': enable,
      'tglSaldoAwal': tglSaldoAwal?.toIso8601String(),
      'itemCode': itemCode,
    };
  }

  // ==== copyWith ====

  RejectType copyWith({
    int? idReject,
    String? namaReject,
    double? saldoAwal,
    bool? enable,
    DateTime? tglSaldoAwal,
    String? itemCode,
  }) {
    return RejectType(
      idReject: idReject ?? this.idReject,
      namaReject: namaReject ?? this.namaReject,
      saldoAwal: saldoAwal ?? this.saldoAwal,
      enable: enable ?? this.enable,
      tglSaldoAwal: tglSaldoAwal ?? this.tglSaldoAwal,
      itemCode: itemCode ?? this.itemCode,
    );
  }

  // ==== equality (by ID) ====

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RejectType && other.idReject == idReject;

  @override
  int get hashCode => idReject.hashCode;

  @override
  String toString() =>
      'RejectType(id: $idReject, nama: $namaReject, saldoAwal: $saldoAwal, enable: $enable)';
}
