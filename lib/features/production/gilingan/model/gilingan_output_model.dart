class GilinganOutput {
  final String noProduksi;
  final String noGilingan;
  final int idJenis;
  final String namaJenis;
  final bool hasBeenPrinted;
  final double berat;

  const GilinganOutput({
    required this.noProduksi,
    required this.noGilingan,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.berat,
  });

  factory GilinganOutput.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return GilinganOutput(
      noProduksi: (j['NoProduksi'] ?? '').toString(),
      noGilingan: (j['NoGilingan'] ?? '').toString(),
      idJenis: (j['IdJenis'] as num?)?.toInt() ?? 0,
      namaJenis: (j['NamaJenis'] ?? '').toString(),
      hasBeenPrinted: (j['HasBeenPrinted'] as num?)?.toInt() == 1,
      berat: toDouble(j['Berat']),
    );
  }
}
