import 'penjualan_label_scan_model.dart';

class PenjualanLine {
  final String kodeKategori;
  final int idJenis;
  final String? namaJenis;
  final int pcsRequired;
  final int pcsScanned;
  final bool isComplete;
  final DateTime? dateTimeCreate;
  final List<PenjualanLabelScan> scans;

  const PenjualanLine({
    required this.kodeKategori,
    required this.idJenis,
    this.namaJenis,
    required this.pcsRequired,
    required this.pcsScanned,
    required this.isComplete,
    this.dateTimeCreate,
    this.scans = const [],
  });

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return false;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v.trim());
    return null;
  }

  factory PenjualanLine.fromJson(Map<String, dynamic> j) {
    final rawScans = j['scans'] ?? j['Scans'];
    final scans = (rawScans is List ? rawScans : <dynamic>[])
        .map((e) => PenjualanLabelScan.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PenjualanLine(
      kodeKategori: (j['kodeKategori'] ?? j['KodeKategori'] ?? '').toString(),
      idJenis: _asInt(j['idJenis'] ?? j['IdJenis']),
      namaJenis: (j['namaJenis'] ?? j['NamaJenis'])?.toString(),
      pcsRequired: _asInt(j['pcsRequired'] ?? j['PcsRequired']),
      pcsScanned: _asInt(j['pcsScanned'] ?? j['PcsScanned']),
      isComplete: _asBool(j['isComplete'] ?? j['IsComplete']),
      dateTimeCreate: _asDateTime(
        j['dateTimeCreate'] ?? j['DateTimeCreate'],
      ),
      scans: scans,
    );
  }

  int get pcsSisa => (pcsRequired - pcsScanned).clamp(0, pcsRequired);

  String get kategoriLabel =>
      kodeKategori == 'furniturewip' ? 'Furniture WIP' : 'Barang Jadi';
}
