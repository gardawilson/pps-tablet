class SpannerOutput {
  final String noProduksi;
  final String noFurnitureWip;
  final int idJenis;
  final String namaJenis;
  final bool hasBeenPrinted;
  final double berat;
  final int pcs;
  final String category;

  const SpannerOutput({
    required this.noProduksi,
    required this.noFurnitureWip,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.berat,
    required this.pcs,
    required this.category,
  });

  bool get isReject => category == 'reject';
  String get labelCode => noFurnitureWip;

  factory SpannerOutput.fromJson(
    Map<String, dynamic> j, {
    String category = 'fwip',
  }) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    bool asBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v != 0;
      return false;
    }

    final labelCode = category == 'reject'
        ? (j['NoReject']?.toString() ?? j['NoFurnitureWIP']?.toString() ?? '')
        : (j['NoFurnitureWIP']?.toString() ?? j['NoReject']?.toString() ?? '');

    return SpannerOutput(
      noProduksi: j['NoProduksi']?.toString() ?? '',
      noFurnitureWip: labelCode,
      idJenis: asInt(j['IdJenis']),
      namaJenis: j['NamaJenis']?.toString() ?? '',
      hasBeenPrinted: asBool(j['HasBeenPrinted']),
      berat: asDouble(j['Berat']),
      pcs: asInt(j['Pcs']),
      category: category,
    );
  }
}
