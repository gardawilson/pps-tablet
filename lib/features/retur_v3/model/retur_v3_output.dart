/// Satu baris output (Furniture WIP / Barang Jadi / Reject) hasil retur v3 —
/// mirrors `lib/features/retur_v2/model/retur_v2_output.dart` shape since the
/// `/outputs` endpoint is documented to return the same shape. Parsing is
/// tolerant of both PascalCase (legacy label tables) and camelCase (contract
/// spec) keys since the exact backend response wasn't observable while this
/// was written — `hasBeenPrinted` is accepted as either a bool or a print
/// count number.
class ReturV3Output {
  final String labelCode;
  final DateTime? dateCreate;
  final String? namaJenis;
  final String kodeKategori;
  final String kategori;
  final String uom;
  final String? blok;
  final int? idLokasi;
  final num qty;

  /// Jumlah berapa kali label ini sudah dicetak — 0 berarti belum pernah.
  final int printCount;

  const ReturV3Output({
    required this.labelCode,
    this.dateCreate,
    this.namaJenis,
    required this.kodeKategori,
    required this.kategori,
    required this.uom,
    this.blok,
    this.idLokasi,
    required this.qty,
    required this.printCount,
  });

  bool get hasBeenPrinted => printCount > 0;

  String? get lokasiLabel =>
      (blok == null || idLokasi == null) ? null : '$blok$idLokasi';

  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int _printCountOf(dynamic v) {
    if (v == null) return 0;
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v.toInt();
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return 1;
      if (s == 'false' || s.isEmpty) return 0;
      return int.tryParse(s) ?? 0;
    }
    return 0;
  }

  factory ReturV3Output.fromJson(Map<String, dynamic> j) {
    final idLokasiRaw = _pick(j, ['idLokasi', 'IdLokasi']);
    return ReturV3Output(
      labelCode: (_pick(j, [
                'labelCode',
                'LabelCode',
                'NoFurnitureWIP',
                'NoBJ',
                'NoReject',
              ]) ??
              '')
          .toString(),
      dateCreate: DateTime.tryParse(
        (_pick(j, ['dateCreate', 'DateCreate']) ?? '').toString(),
      ),
      namaJenis: _pick(j, ['namaJenis', 'NamaJenis'])?.toString(),
      kodeKategori: (_pick(j, ['kodeKategori', 'KodeKategori']) ?? '')
          .toString()
          .toLowerCase(),
      kategori: (_pick(j, ['kategori', 'Kategori']) ?? '').toString(),
      uom: (_pick(j, ['uom', 'Uom']) ?? '').toString(),
      blok: _pick(j, ['blok', 'Blok'])?.toString(),
      idLokasi: idLokasiRaw is num
          ? idLokasiRaw.toInt()
          : int.tryParse('$idLokasiRaw'),
      qty: (_pick(j, ['qty', 'Qty']) as num?) ?? 0,
      printCount: _printCountOf(
        _pick(j, ['hasBeenPrinted', 'HasBeenPrinted']),
      ),
    );
  }
}
