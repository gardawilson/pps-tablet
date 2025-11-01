class CrusherType {
  final int idCrusher;
  final String namaCrusher;
  final bool enable; // backend returns only active, but keep for completeness

  const CrusherType({
    required this.idCrusher,
    required this.namaCrusher,
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
  factory CrusherType.fromJson(Map<String, dynamic> j) {
    final id = j['IdCrusher'] ?? j['idCrusher'];
    final nama = j['NamaCrusher'] ?? j['namaCrusher'] ?? '';
    final enable = j['Enable'] ?? j['enable'];

    return CrusherType(
      idCrusher: _toInt(id),
      namaCrusher: nama.toString(),
      enable: _toBool(enable, def: true),
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdCrusher': idCrusher,
        'NamaCrusher': namaCrusher,
        'Enable': enable,
      };
    }
    return {
      'idCrusher': idCrusher,
      'namaCrusher': namaCrusher,
      'enable': enable,
    };
  }

  // ==== copyWith ====
  CrusherType copyWith({
    int? idCrusher,
    String? namaCrusher,
    bool? enable,
  }) {
    return CrusherType(
      idCrusher: idCrusher ?? this.idCrusher,
      namaCrusher: namaCrusher ?? this.namaCrusher,
      enable: enable ?? this.enable,
    );
  }

  // ==== equality (by ID) ====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CrusherType && other.idCrusher == idCrusher;

  @override
  int get hashCode => idCrusher.hashCode;

  @override
  String toString() =>
      'CrusherType(id: $idCrusher, nama: $namaCrusher, enable: $enable)';
}
