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

/// Progress turnover per item (dipakai saat statusRetur == DIGANTI):
/// targetPcs adalah pcs yang harus dipenuhi lewat scan label existing,
/// scannedPcs adalah total pcs yang sudah discan.
class ReturV3Turnover {
  final int idItem;
  final int targetPcs;
  final int scannedPcs;
  final List<ReturV3ScanEntry> scans;

  const ReturV3Turnover({
    required this.idItem,
    required this.targetPcs,
    required this.scannedPcs,
    this.scans = const [],
  });

  bool get isFulfilled => scannedPcs >= targetPcs && targetPcs > 0;
  int get remainingPcs => (targetPcs - scannedPcs).clamp(0, targetPcs);

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
    final scansRaw = _listFrom(_pick(j, ['scans', 'Scans']));
    return ReturV3Turnover(
      idItem: _i(_pick(j, ['idItem', 'IdItem'])),
      targetPcs: _i(_pick(j, ['targetPcs', 'TargetPcs'])),
      scannedPcs: _i(_pick(j, ['scannedPcs', 'ScannedPcs'])),
      scans: scansRaw
          .whereType<Map>()
          .map((e) => ReturV3ScanEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
