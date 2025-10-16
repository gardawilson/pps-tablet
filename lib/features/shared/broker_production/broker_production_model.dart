import 'package:intl/intl.dart';

class BrokerProduction {
  final String noProduksi;
  final int idOperator;
  final int idMesin;
  final String namaMesin;
  final DateTime? tglProduksi;
  final int jamKerja;
  final int shift;
  final String createBy;
  final int? jmlhAnggota;
  final int? hadir;
  final int? hourMeter;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;

  const BrokerProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.tglProduksi,
    required this.jamKerja,
    required this.shift,
    required this.createBy,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
  });

  // ===== Factory fromJson =====
  factory BrokerProduction.fromJson(Map<String, dynamic> j) {
    return BrokerProduction(
      noProduksi: j['NoProduksi'] ?? '',
      idOperator: j['IdOperator'] ?? 0,
      idMesin: j['IdMesin'] ?? 0,
      namaMesin: j['NamaMesin'] ?? '',
      tglProduksi: j['TglProduksi'] != null
          ? DateTime.tryParse(j['TglProduksi'])
          : null,
      jamKerja: j['JamKerja'] ?? 0,
      shift: j['Shift'] ?? 0,
      createBy: j['CreateBy'] ?? '',
      checkBy1: j['CheckBy1'],
      checkBy2: j['CheckBy2'],
      approveBy: j['ApproveBy'],
      jmlhAnggota: j['JmlhAnggota'],
      hadir: j['Hadir'],
      hourMeter: j['HourMeter'],
    );
  }

  // ===== toJson =====
  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoProduksi': noProduksi,
    'IdOperator': idOperator,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'TglProduksi': tglProduksi == null
        ? null
        : (asDateOnly
        ? DateFormat('yyyy-MM-dd').format(tglProduksi!.toUtc())
        : tglProduksi!.toUtc().toIso8601String()),
    'JamKerja': jamKerja,
    'Shift': shift,
    'CreateBy': createBy,
    'CheckBy1': checkBy1,
    'CheckBy2': checkBy2,
    'ApproveBy': approveBy,
    'JmlhAnggota': jmlhAnggota,
    'Hadir': hadir,
    'HourMeter': hourMeter,
  };

  // ===== Helpers tampilan =====
  String get tglProduksiTextShort {
    if (tglProduksi == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get tglProduksiTextFull {
    if (tglProduksi == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }
}
