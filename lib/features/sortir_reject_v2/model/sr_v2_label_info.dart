class SrV2LabelInfo {
  final String labelCode;
  final String category;
  final int idJenis;
  final String namaJenis;
  final int pcs;

  const SrV2LabelInfo({
    required this.labelCode,
    required this.category,
    required this.idJenis,
    required this.namaJenis,
    required this.pcs,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory SrV2LabelInfo.fromJson(Map<String, dynamic> j) {
    return SrV2LabelInfo(
      labelCode: _s(j['labelCode']),
      category: _s(j['category']),
      idJenis: _i(j['idJenis']),
      namaJenis: _s(j['namaJenis']),
      pcs: _i(j['pcs']),
    );
  }
}
