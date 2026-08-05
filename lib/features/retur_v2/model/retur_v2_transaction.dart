class ReturV2Transaction {
  final String noRetur;
  final String? invoice;
  final DateTime? tanggal;
  final int? idPembeli;
  final String? namaPembeli;
  final String? noBJSortir;
  final DateTime? lastClosedDate;
  final bool isLocked;

  const ReturV2Transaction({
    required this.noRetur,
    this.invoice,
    this.tanggal,
    this.idPembeli,
    this.namaPembeli,
    this.noBJSortir,
    this.lastClosedDate,
    this.isLocked = false,
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static String? _sOpt(dynamic v) {
    if (v == null) return null;
    final text = v.toString();
    return text.isEmpty ? null : text;
  }

  static int? _iOpt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _dtOpt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    return v.toString().toLowerCase() == 'true';
  }

  factory ReturV2Transaction.fromJson(Map<String, dynamic> j) {
    return ReturV2Transaction(
      noRetur: _s(j['NoRetur'] ?? j['noRetur']),
      invoice: _sOpt(j['Invoice'] ?? j['invoice']),
      tanggal: _dtOpt(j['Tanggal'] ?? j['tanggal']),
      idPembeli: _iOpt(j['IdPembeli'] ?? j['idPembeli']),
      namaPembeli: _sOpt(j['NamaPembeli'] ?? j['namaPembeli']),
      noBJSortir: _sOpt(j['NoBJSortir'] ?? j['noBJSortir']),
      lastClosedDate: _dtOpt(j['LastClosedDate'] ?? j['lastClosedDate']),
      isLocked: _b(j['IsLocked'] ?? j['isLocked']),
    );
  }
}
