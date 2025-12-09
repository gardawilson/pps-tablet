class PackingProduction {
  final String noPacking;
  final DateTime tanggal;
  final int idMesin;
  final String namaMesin;
  final int idOperator;
  final String namaOperator;
  final int shift;
  final int jamKerja;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final num? hourMeter;
  final num? hourStart;
  final num? hourEnd;

  PackingProduction({
    required this.noPacking,
    required this.tanggal,
    required this.idMesin,
    required this.namaMesin,
    required this.idOperator,
    required this.namaOperator,
    required this.shift,
    required this.jamKerja,
    this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.hourMeter,
    this.hourStart,
    this.hourEnd,
  });

  factory PackingProduction.fromJson(Map<String, dynamic> j) {
    T? _castNum<T extends num>(dynamic v) {
      if (v == null) return null;
      if (v is num) return v as T;
      if (v is String) return num.tryParse(v) as T?;
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
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

    return PackingProduction(
      noPacking: (j['NoPacking'] ?? '') as String,
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
      hourMeter: _castNum<num>(j['HourMeter']),
      hourStart: _castNum<num>(j['HourStart']),
      hourEnd: _castNum<num>(j['HourEnd']),
    );
  }
}
