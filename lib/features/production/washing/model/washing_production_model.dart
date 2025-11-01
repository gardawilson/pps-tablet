// lib/features/shared/washing_production/model/washing_production_model.dart
class WashingProduction {
  final String noProduksi;
  final int idOperator;
  final String namaOperator;
  final int idMesin;
  final String namaMesin;
  final DateTime tglProduksi;
  final int jamKerja;
  final int shift;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int jmlhAnggota;
  final int hadir;
  final num hourMeter;

  WashingProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.namaOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.tglProduksi,
    required this.jamKerja,
    required this.shift,
    required this.createBy,
    required this.checkBy1,
    required this.checkBy2,
    required this.approveBy,
    required this.jmlhAnggota,
    required this.hadir,
    required this.hourMeter,
  });

  factory WashingProduction.fromJson(Map<String, dynamic> j) => WashingProduction(
    noProduksi: j['NoProduksi'] as String,
    idOperator: (j['IdOperator'] ?? 0) as int,
    namaOperator: (j['NamaOperator'] ?? '') as String,
    idMesin: (j['IdMesin'] ?? 0) as int,
    namaMesin: (j['NamaMesin'] ?? '') as String,
    tglProduksi: DateTime.parse(j['TglProduksi'] as String),
    jamKerja: (j['JamKerja'] ?? 0) as int,
    shift: (j['Shift'] ?? 0) as int,
    createBy: j['CreateBy'] as String?,
    checkBy1: j['CheckBy1'] as String?,
    checkBy2: j['CheckBy2'] as String?,
    approveBy: j['ApproveBy'] as String?,
    jmlhAnggota: (j['JmlhAnggota'] ?? 0) as int,
    hadir: (j['Hadir'] ?? 0) as int,
    hourMeter: (j['HourMeter'] ?? 0) as num,
  );
}