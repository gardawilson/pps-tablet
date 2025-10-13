class JenisPlastik {
  final int idJenisPlastik;
  final String jenis;
  final bool enable;
  final bool isReject;
  final int? idWarna;
  final double? moisture;
  final double? meltingIndex;
  final double? elasticity;

  const JenisPlastik({
    required this.idJenisPlastik,
    required this.jenis,
    required this.enable,
    required this.isReject,
    this.idWarna,
    this.moisture,
    this.meltingIndex,
    this.elasticity,
  });

  // ==== Helpers konversi aman ====
  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double? _toDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _toBool(dynamic v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return defaultValue;
  }

  // ==== JSON ====
  factory JenisPlastik.fromJson(Map<String, dynamic> j) {
    // dukung PascalCase/camelCase
    final id = j['IdJenisPlastik'] ?? j['idJenisPlastik'];
    final jenis = j['Jenis'] ?? j['jenis'] ?? '';
    final enable = j['Enable'] ?? j['enable'];
    final isReject = j['IsReject'] ?? j['isReject'];
    final idWarna = j['IdWarna'] ?? j['idWarna'];
    final moisture = j['Moisture'] ?? j['moisture'];
    final meltingIndex = j['MeltingIndex'] ?? j['meltingIndex'];
    final elasticity = j['Elasticity'] ?? j['elasticity'];

    return JenisPlastik(
      idJenisPlastik: _toInt(id),
      jenis: jenis.toString(),
      enable: _toBool(enable),
      isReject: _toBool(isReject),
      idWarna: idWarna == null ? null : _toInt(idWarna),
      moisture: _toDoubleNullable(moisture),
      meltingIndex: _toDoubleNullable(meltingIndex),
      elasticity: _toDoubleNullable(elasticity),
    );
  }

  Map<String, dynamic> toJson({bool useServerCase = true}) {
    if (useServerCase) {
      return {
        'IdJenisPlastik': idJenisPlastik,
        'Jenis': jenis,
        'Enable': enable,
        'IsReject': isReject,
        'IdWarna': idWarna,
        'Moisture': moisture,
        'MeltingIndex': meltingIndex,
        'Elasticity': elasticity,
      };
    }
    return {
      'idJenisPlastik': idJenisPlastik,
      'jenis': jenis,
      'enable': enable,
      'isReject': isReject,
      'idWarna': idWarna,
      'moisture': moisture,
      'meltingIndex': meltingIndex,
      'elasticity': elasticity,
    };
  }

  // ==== copyWith ====
  JenisPlastik copyWith({
    int? idJenisPlastik,
    String? jenis,
    bool? enable,
    bool? isReject,
    int? idWarna,
    double? moisture,
    double? meltingIndex,
    double? elasticity,
  }) {
    return JenisPlastik(
      idJenisPlastik: idJenisPlastik ?? this.idJenisPlastik,
      jenis: jenis ?? this.jenis,
      enable: enable ?? this.enable,
      isReject: isReject ?? this.isReject,
      idWarna: idWarna ?? this.idWarna,
      moisture: moisture ?? this.moisture,
      meltingIndex: meltingIndex ?? this.meltingIndex,
      elasticity: elasticity ?? this.elasticity,
    );
  }

  // ==== Equality untuk Dropdown (berbasis ID) ====
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JenisPlastik && other.idJenisPlastik == idJenisPlastik;

  @override
  int get hashCode => idJenisPlastik.hashCode;

  @override
  String toString() =>
      'JenisPlastik(id: $idJenisPlastik, jenis: $jenis, enable: $enable, isReject: $isReject)';
}
