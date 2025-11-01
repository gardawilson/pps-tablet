// lib/features/shared/bonggolan_type/jenis_bonggolan_model.dart
class JenisBonggolan {
  final int idBonggolan;
  final String namaBonggolan;
  final bool enable; // backend returns only active, but keep for completeness

  const JenisBonggolan({
    required this.idBonggolan,
    required this.namaBonggolan,
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
  factory JenisBonggolan.fromJson(Map<String, dynamic> j) {
    final id = j['IdBonggolan'] ?? j['idBonggolan'];
    final nama = j['NamaBonggolan'] ?? j['namaBonggolan'] ?? '';
    final enable = j['Enable'] ?? j['enable'];

    return JenisBonggolan(
      idBonggolan: _toInt(id),
      namaBonggolan: nama.toString(),
      enable: _toBool(enable, def: true),
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdBonggolan': idBonggolan,
        'NamaBonggolan': namaBonggolan,
        'Enable': enable,
      };
    }
    return {
      'idBonggolan': idBonggolan,
      'namaBonggolan': namaBonggolan,
      'enable': enable,
    };
  }

  // ==== copyWith ====
  JenisBonggolan copyWith({
    int? idBonggolan,
    String? namaBonggolan,
    bool? enable,
  }) {
    return JenisBonggolan(
      idBonggolan: idBonggolan ?? this.idBonggolan,
      namaBonggolan: namaBonggolan ?? this.namaBonggolan,
      enable: enable ?? this.enable,
    );
  }

  // ==== equality (by ID) ====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JenisBonggolan && other.idBonggolan == idBonggolan;

  @override
  int get hashCode => idBonggolan.hashCode;

  @override
  String toString() =>
      'JenisBonggolan(id: $idBonggolan, nama: $namaBonggolan, enable: $enable)';
}
