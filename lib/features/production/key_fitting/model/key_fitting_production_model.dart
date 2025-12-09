// lib/features/shared/key_fitting_production/model/packing_production_model.dart

class KeyFittingProduction {
  final String noProduksi;
  final int idMesin;
  final String namaMesin;
  final int idOperator;
  final String namaOperator;
  final DateTime tanggal;
  final int shift;
  final int jamKerja;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final num? hourMeter;

  KeyFittingProduction({
    required this.noProduksi,
    required this.idMesin,
    required this.namaMesin,
    required this.idOperator,
    required this.namaOperator,
    required this.tanggal,
    required this.shift,
    required this.jamKerja,
    this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.hourMeter,
  });

  factory KeyFittingProduction.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    num? _toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          try {
            return DateTime.parse('${v}T00:00:00');
          } catch (_) {
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    return KeyFittingProduction(
      noProduksi: (j['NoProduksi'] ?? '') as String,
      tanggal: _parseDate(j['Tanggal']),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: (j['NamaMesin'] ?? '') as String,
      idOperator: _toInt(j['IdOperator']),
      namaOperator: (j['NamaOperator'] ?? '') as String,
      shift: _toInt(j['Shift']),
      jamKerja: _toInt(j['JamKerja']),
      createBy: j['CreateBy'] as String?,
      checkBy1: j['CheckBy1'] as String?,
      checkBy2: j['CheckBy2'] as String?,
      approveBy: j['ApproveBy'] as String?,
      hourMeter: _toNum(j['HourMeter']),
    );
  }
}
