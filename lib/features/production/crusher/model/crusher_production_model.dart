class CrusherProduction {
  final String noCrusherProduksi;   // h.NoCrusherProduksi
  final DateTime tanggal;           // h.Tanggal (date only)
  final int idMesin;                // h.IdMesin
  final String namaMesin;           // m.NamaMesin
  final int idOperator;             // h.IdOperator
  final String? jam;                // h.Jam (often string like "07:30")
  final String shift;               // h.Shift (string in many DBs; adjust if int)
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int jmlhAnggota;
  final int hadir;
  final num? hourMeter;

  /// Comma-separated outputs from subquery: "CR.0001, CR.0002"
  final String? outputNoCrusher;

  /// Convenience: parsed list of outputs (trimmed)
  List<String> get outputNoCrusherList =>
      (outputNoCrusher ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  const CrusherProduction({
    required this.noCrusherProduksi,
    required this.tanggal,
    required this.idMesin,
    required this.namaMesin,
    required this.idOperator,
    required this.jam,
    required this.shift,
    required this.createBy,
    required this.checkBy1,
    required this.checkBy2,
    required this.approveBy,
    required this.jmlhAnggota,
    required this.hadir,
    required this.hourMeter,
    required this.outputNoCrusher,
  });

  factory CrusherProduction.fromJson(Map<String, dynamic> j) {
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

    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Invalid date: $v');
    }

    return CrusherProduction(
      noCrusherProduksi: (j['NoCrusherProduksi'] ?? '') as String,
      tanggal: _toDate(j['Tanggal']),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: (j['NamaMesin'] ?? '') as String,
      idOperator: _toInt(j['IdOperator']),
      jam: j['Jam']?.toString(),
      shift: (j['Shift'] ?? '').toString(),
      createBy: j['CreateBy'] as String?,
      checkBy1: j['CheckBy1'] as String?,
      checkBy2: j['CheckBy2'] as String?,
      approveBy: j['ApproveBy'] as String?,
      jmlhAnggota: _toInt(j['JmlhAnggota']),
      hadir: _toInt(j['Hadir']),
      hourMeter: _toNum(j['HourMeter']),
      outputNoCrusher: j['OutputNoCrusher'] as String?,
    );
  }
}
