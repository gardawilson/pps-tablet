/// Satu baris label yang berhasil discan untuk memenuhi 1 baris turnover
/// (`PenjualanLine`) — dipakai untuk menampilkan chip nomor label, meniru
/// `ReturV3Turnover.scans` di `retur_v3_turnover.dart`.
class PenjualanLabelScan {
  final int id;
  final String noLabel;
  final int pcs;
  final DateTime? dateTimeScan;

  const PenjualanLabelScan({
    required this.id,
    required this.noLabel,
    required this.pcs,
    this.dateTimeScan,
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v.trim());
    return null;
  }

  factory PenjualanLabelScan.fromJson(Map<String, dynamic> j) {
    return PenjualanLabelScan(
      id: _asInt(j['id'] ?? j['Id']),
      noLabel: (j['noLabel'] ?? j['NoLabel'] ?? '').toString(),
      pcs: _asInt(j['pcs'] ?? j['Pcs']),
      dateTimeScan: _asDateTime(j['dateTimeScan'] ?? j['DateTimeScan']),
    );
  }
}
