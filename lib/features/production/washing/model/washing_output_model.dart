// lib/features/production/washing/model/washing_output_model.dart
//
// Model untuk output produksi washing.
// Endpoint: GET /api/production/washing/:noProduksi/outputs
// Response data[] berisi list objek ini.

class WashingOutputSak {
  final int noSak;
  final double berat;

  const WashingOutputSak({required this.noSak, required this.berat});

  factory WashingOutputSak.fromJson(Map<String, dynamic> j) =>
      WashingOutputSak(
        noSak: (j['NoSak'] as num?)?.toInt() ?? 0,
        berat: (j['Berat'] as num?)?.toDouble() ?? 0.0,
      );
}

class WashingOutput {
  final String noProduksi;
  final String noWashing;
  final int idJenis;
  final String namaJenis;
  final int hasPrinted; // HasBeenPrinted
  final List<WashingOutputSak> detailSak;

  WashingOutput({
    required this.noProduksi,
    required this.noWashing,
    required this.idJenis,
    required this.namaJenis,
    required this.hasPrinted,
    required this.detailSak,
  });

  int get totalSak => detailSak.length;
  double get totalBerat =>
      detailSak.fold(0.0, (sum, s) => sum + s.berat);

  factory WashingOutput.fromJson(Map<String, dynamic> j) => WashingOutput(
    noProduksi: j['NoProduksi'] as String? ?? '',
    noWashing: j['NoWashing'] as String? ?? '-',
    idJenis: (j['IdJenis'] as num?)?.toInt() ?? 0,
    namaJenis: j['NamaJenis'] as String? ?? '-',
    hasPrinted: (j['HasBeenPrinted'] as num?)?.toInt() ?? 0,
    detailSak: (j['DetailSak'] as List? ?? [])
        .map(
          (e) => WashingOutputSak.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(),
  );
}
