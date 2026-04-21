class BsV2LabelSak {
  final int noSak;
  final double berat;

  const BsV2LabelSak({required this.noSak, required this.berat});

  factory BsV2LabelSak.fromJson(Map<String, dynamic> j) {
    return BsV2LabelSak(
      noSak: j['noSak'] is int ? j['noSak'] as int : int.tryParse(j['noSak']?.toString() ?? '0') ?? 0,
      berat: j['berat'] is double
          ? j['berat'] as double
          : (j['berat'] is int ? (j['berat'] as int).toDouble() : double.tryParse(j['berat']?.toString() ?? '0') ?? 0.0),
    );
  }
}

class BsV2LabelInfo {
  final String labelCode;
  final String category; // "washing" | "bonggolan"
  final int idJenis;
  final String namaJenis;
  final double totalBerat;
  final int jumlahSak;
  final List<BsV2LabelSak> saks;

  const BsV2LabelInfo({
    required this.labelCode,
    required this.category,
    required this.idJenis,
    required this.namaJenis,
    required this.totalBerat,
    this.jumlahSak = 0,
    this.saks = const [],
  });

  bool get isWashing => category == 'washing';
  bool get isBonggolan => category == 'bonggolan';

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory BsV2LabelInfo.fromJson(Map<String, dynamic> j) {
    final saksRaw = (j['saks'] ?? []) as List;
    return BsV2LabelInfo(
      labelCode: _s(j['labelCode']),
      category: _s(j['category']),
      idJenis: _i(j['idJenis']),
      namaJenis: _s(j['namaJenis']),
      totalBerat: _d(j['totalBerat']),
      jumlahSak: _i(j['jumlahSak']),
      saks: saksRaw
          .map((e) => BsV2LabelSak.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
