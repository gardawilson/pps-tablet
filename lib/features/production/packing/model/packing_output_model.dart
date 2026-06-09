class PackingOutput {
  final String noPacking;
  final String noBJ;
  final int idJenis;
  final String namaJenis;
  final int hasBeenPrinted;
  final int pcs;

  const PackingOutput({
    required this.noPacking,
    required this.noBJ,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.pcs,
  });

  bool get isPrinted => hasBeenPrinted > 0;
  String get labelCode => noBJ;

  factory PackingOutput.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return PackingOutput(
      noPacking: j['NoPacking']?.toString() ?? '',
      noBJ: j['NoBJ']?.toString() ?? '',
      idJenis: asInt(j['IdJenis']),
      namaJenis: j['NamaJenis']?.toString() ?? '',
      hasBeenPrinted: asInt(j['HasBeenPrinted']),
      pcs: asInt(j['Pcs']),
    );
  }
}
