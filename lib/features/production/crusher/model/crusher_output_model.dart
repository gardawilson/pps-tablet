// lib/features/production/crusher/model/crusher_output_model.dart

class CrusherOutput {
  final String noProduksi;
  final String noCrusher;
  final int idJenis;
  final String namaJenis;
  final int hasBeenPrinted;
  final double berat;

  const CrusherOutput({
    required this.noProduksi,
    required this.noCrusher,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.berat,
  });

  factory CrusherOutput.fromJson(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return CrusherOutput(
      noProduksi: (j['NoProduksi'] ?? '').toString(),
      noCrusher: (j['NoCrusher'] ?? '').toString(),
      idJenis: (j['IdJenis'] as num?)?.toInt() ?? 0,
      namaJenis: (j['NamaJenis'] ?? '').toString(),
      hasBeenPrinted: (j['HasBeenPrinted'] as num?)?.toInt() ?? 0,
      berat: toDouble(j['Berat']),
    );
  }
}
