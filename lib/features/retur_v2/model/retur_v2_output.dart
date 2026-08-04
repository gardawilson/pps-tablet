/// Satu baris output (Furniture WIP atau Barang Jadi) hasil retur — kedua
/// endpoint sekarang punya bentuk identik jadi cukup satu model.
class ReturV2Output {
  final String labelCode;
  final String? dateCreate;
  final String? namaJenis;
  final String kodeKategori;
  final String kategori;
  final String uom;
  final String? blok;
  final int? idLokasi;
  final num qty;
  final bool hasBeenPrinted;

  const ReturV2Output({
    required this.labelCode,
    this.dateCreate,
    this.namaJenis,
    required this.kodeKategori,
    required this.kategori,
    required this.uom,
    this.blok,
    this.idLokasi,
    required this.qty,
    required this.hasBeenPrinted,
  });

  /// Label lokasi gabungan mis. "A5" — null kalau Blok/IdLokasi tidak ada
  /// (header FurnitureWIP/BarangJadi tidak ketemu, LEFT JOIN).
  String? get lokasiLabel =>
      (blok == null || idLokasi == null) ? null : '$blok$idLokasi';

  factory ReturV2Output.fromJson(Map<String, dynamic> json) {
    final printedRaw = json['HasBeenPrinted'];
    final idLokasiRaw = json['IdLokasi'];
    return ReturV2Output(
      labelCode: (json['LabelCode'] ?? '').toString(),
      dateCreate: json['DateCreate']?.toString(),
      namaJenis: json['NamaJenis']?.toString(),
      kodeKategori: (json['KodeKategori'] ?? '').toString(),
      kategori: (json['Kategori'] ?? '').toString(),
      uom: (json['Uom'] ?? '').toString(),
      blok: json['Blok']?.toString(),
      idLokasi: idLokasiRaw is num
          ? idLokasiRaw.toInt()
          : int.tryParse('$idLokasiRaw'),
      qty: (json['Qty'] as num?) ?? 0,
      hasBeenPrinted: printedRaw == 1 || printedRaw == true,
    );
  }
}
