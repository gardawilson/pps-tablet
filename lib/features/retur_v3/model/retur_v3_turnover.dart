class ReturV3ScanEntry {
  final int idTurnover;
  final String labelCode;
  final int pcs;
  final DateTime? dateTimeScan;

  const ReturV3ScanEntry({
    required this.idTurnover,
    required this.labelCode,
    required this.pcs,
    this.dateTimeScan,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory ReturV3ScanEntry.fromJson(Map<String, dynamic> j) {
    return ReturV3ScanEntry(
      idTurnover: _i(_pick(j, ['idTurnover', 'IdTurnover'])),
      labelCode: _s(_pick(j, ['labelCode', 'LabelCode'])),
      pcs: _i(_pick(j, ['pcs', 'Pcs'])),
      dateTimeScan: (_pick(j, ['dateTimeScan', 'DateTimeScan']) != null)
          ? DateTime.tryParse(
              _pick(j, ['dateTimeScan', 'DateTimeScan']).toString(),
            )
          : null,
    );
  }
}

/// Satu target pengganti (barang yang akan dikirim) untuk sebuah item retur
/// — 1 item retur bisa punya beberapa target (kombinasi jenis pengganti).
/// targetPcs adalah pcs yang harus dipenuhi lewat scan label existing,
/// scannedPcs adalah total pcs yang sudah discan untuk target ini.
class ReturV3TurnoverTarget {
  final int idTarget;
  final String kodeKategori;
  final int idJenis;
  final String? namaJenis;
  final int targetPcs;
  final int scannedPcs;
  final List<ReturV3ScanEntry> scans;

  const ReturV3TurnoverTarget({
    required this.idTarget,
    required this.kodeKategori,
    required this.idJenis,
    this.namaJenis,
    required this.targetPcs,
    required this.scannedPcs,
    this.scans = const [],
  });

  bool get isFulfilled => scannedPcs >= targetPcs && targetPcs > 0;
  int get remainingPcs => (targetPcs - scannedPcs).clamp(0, targetPcs);

  static String _s(dynamic v) => v?.toString() ?? '';
  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<dynamic> _listFrom(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    return const [];
  }

  factory ReturV3TurnoverTarget.fromJson(Map<String, dynamic> j) {
    final scansRaw = _listFrom(_pick(j, ['scans', 'Scans']));
    return ReturV3TurnoverTarget(
      idTarget: _i(_pick(j, ['idTarget', 'IdTarget'])),
      kodeKategori: _s(
        _pick(j, ['kodeKategori', 'KodeKategori']),
      ).toLowerCase(),
      idJenis: _i(_pick(j, ['idJenis', 'IdJenis'])),
      namaJenis: _pick(j, ['namaJenis', 'NamaJenis'])?.toString(),
      targetPcs: _i(_pick(j, ['targetPcs', 'TargetPcs'])),
      scannedPcs: _i(_pick(j, ['scannedPcs', 'ScannedPcs'])),
      scans: scansRaw
          .whereType<Map>()
          .map((e) => ReturV3ScanEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Progress turnover per item retur (dipakai saat statusRetur == DIGANTI):
/// mengelompokkan target-target pengganti (bisa lebih dari satu, dengan
/// kategori/jenis berbeda dari item asalnya) di bawah item retur asalnya.
class ReturV3Turnover {
  final int idItem;
  final String kodeKategoriAsal;
  final int idJenisAsal;
  final String? namaJenisAsal;
  final int pcsAsal;
  final List<ReturV3TurnoverTarget> targets;

  const ReturV3Turnover({
    required this.idItem,
    required this.kodeKategoriAsal,
    required this.idJenisAsal,
    this.namaJenisAsal,
    required this.pcsAsal,
    this.targets = const [],
  });

  bool get hasTargets => targets.isNotEmpty;
  bool get isFulfilled => hasTargets && targets.every((t) => t.isFulfilled);

  static String _s(dynamic v) => v?.toString() ?? '';
  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<dynamic> _listFrom(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    return const [];
  }

  factory ReturV3Turnover.fromJson(Map<String, dynamic> j) {
    final targetsRaw = _listFrom(_pick(j, ['targets', 'Targets']));
    return ReturV3Turnover(
      idItem: _i(_pick(j, ['idItem', 'IdItem'])),
      kodeKategoriAsal: _s(
        _pick(j, ['kodeKategoriAsal', 'KodeKategoriAsal', 'kodeKategori']),
      ).toLowerCase(),
      idJenisAsal: _i(_pick(j, ['idJenisAsal', 'IdJenisAsal', 'idJenis'])),
      namaJenisAsal: _pick(j, [
        'namaJenisAsal',
        'NamaJenisAsal',
        'namaJenis',
      ])?.toString(),
      pcsAsal: _i(_pick(j, ['pcsAsal', 'PcsAsal', 'pcs'])),
      targets: targetsRaw
          .whereType<Map>()
          .map(
            (e) =>
                ReturV3TurnoverTarget.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}
