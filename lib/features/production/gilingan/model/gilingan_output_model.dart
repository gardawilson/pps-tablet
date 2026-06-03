class GilinganOutput {
  final String noProduksi;
  final String noGilingan;
  final int idJenis;
  final String namaJenis;
  final int hasPrinted;
  final double berat;

  const GilinganOutput({
    required this.noProduksi,
    required this.noGilingan,
    required this.idJenis,
    required this.namaJenis,
    required this.hasPrinted,
    required this.berat,
  });

  factory GilinganOutput.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return GilinganOutput(
      noProduksi: (j['NoProduksi'] ?? '').toString(),
      noGilingan: (j['NoGilingan'] ?? '').toString(),
      idJenis: toInt(j['IdJenis']),
      namaJenis: (j['NamaJenis'] ?? '').toString(),
      hasPrinted: toInt(j['HasBeenPrinted']),
      berat: toDouble(j['Berat']),
    );
  }
}
