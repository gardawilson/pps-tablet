class MixerOutputSak {
  final int noSak;
  final double berat;
  final bool isPartial;

  const MixerOutputSak({
    required this.noSak,
    required this.berat,
    this.isPartial = false,
  });

  factory MixerOutputSak.fromJson(Map<String, dynamic> j) => MixerOutputSak(
    noSak: (j['NoSak'] as num?)?.toInt() ?? 0,
    berat: (j['Berat'] as num?)?.toDouble() ?? 0.0,
    isPartial: j['IsPartial'] == true,
  );
}

class MixerOutput {
  final String noProduksi;
  final String noMixer;
  final int idJenis;
  final String namaJenis;
  final int hasPrinted;
  final List<MixerOutputSak> detailSak;

  MixerOutput({
    required this.noProduksi,
    required this.noMixer,
    required this.idJenis,
    required this.namaJenis,
    required this.hasPrinted,
    required this.detailSak,
  });

  int get totalSak => detailSak.length;
  double get totalBerat => detailSak.fold(0.0, (s, e) => s + e.berat);

  factory MixerOutput.fromJson(Map<String, dynamic> j) => MixerOutput(
    noProduksi: j['NoProduksi'] as String? ?? '',
    noMixer: j['NoMixer'] as String? ?? '-',
    idJenis: (j['IdJenis'] as num?)?.toInt() ?? 0,
    namaJenis: j['NamaJenis'] as String? ?? '-',
    hasPrinted: (j['HasBeenPrinted'] as num?)?.toInt() ?? 0,
    detailSak: (j['DetailSak'] as List? ?? [])
        .map((e) => MixerOutputSak.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
