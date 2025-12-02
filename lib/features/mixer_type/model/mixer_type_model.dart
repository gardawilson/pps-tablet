class MixerType {
  final int idMixer;
  final String jenis;
  final bool enable; // backend returns only active, but keep for completeness

  const MixerType({
    required this.idMixer,
    required this.jenis,
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
  factory MixerType.fromJson(Map<String, dynamic> j) {
    final id = j['IdMixer'] ?? j['idMixer'];
    final jenis = j['Jenis'] ?? j['jenis'] ?? '';
    final enable = j['Enable'] ?? j['enable'];

    return MixerType(
      idMixer: _toInt(id),
      jenis: jenis.toString(),
      enable: _toBool(enable, def: true),
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdMixer': idMixer,
        'Jenis': jenis,
        'Enable': enable,
      };
    }
    return {
      'idMixer': idMixer,
      'jenis': jenis,
      'enable': enable,
    };
  }

  // ==== copyWith ====
  MixerType copyWith({
    int? idMixer,
    String? jenis,
    bool? enable,
  }) {
    return MixerType(
      idMixer: idMixer ?? this.idMixer,
      jenis: jenis ?? this.jenis,
      enable: enable ?? this.enable,
    );
  }

  // ==== equality (by ID) ====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MixerType && other.idMixer == idMixer;

  @override
  int get hashCode => idMixer.hashCode;

  @override
  String toString() =>
      'MixerType(id: $idMixer, jenis: $jenis, enable: $enable)';
}
