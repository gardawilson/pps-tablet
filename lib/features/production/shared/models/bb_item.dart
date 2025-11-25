// lib/features/production/shared/models/bb_item.dart
import 'model_helpers.dart';

class BbItem {
  final String? noBahanBaku;
  final int? noPallet;
  final int? noSak;
  final String? noBBPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final DateTime? dateUsage;
  final int? idJenis;
  final String? namaJenis;

  /// Row dianggap "partial" jika ada kode partial ATAU flag isPartial = true
  bool get isPartialRow =>
      (noBBPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  BbItem({
    this.noBahanBaku,
    this.noPallet,
    this.noSak,
    this.noBBPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.dateUsage,
    this.idJenis,
    this.namaJenis,
  });

  factory BbItem.fromJson(Map<String, dynamic> j) => BbItem(
    noBahanBaku: pickS(j, ['noBahanBaku', 'NoBahanBaku', 'no_bahan_baku']),
    noPallet: pickI(j, ['noPallet', 'NoPallet', 'no_pallet']),
    noSak: pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noBBPartial: pickS(j, ['noBBPartial', 'NoBBPartial', 'no_bb_partial']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    dateUsage: pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
    idJenis: pickI(j, ['idJenis', 'IdJenis', 'id_jenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
  );

  BbItem copyWith({
    String? noBahanBaku,
    int? noPallet,
    int? noSak,
    String? noBBPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    DateTime? dateUsage,
    int? idJenis,
    String? namaJenis,
  }) {
    return BbItem(
      noBahanBaku: noBahanBaku ?? this.noBahanBaku,
      noPallet: noPallet ?? this.noPallet,
      noSak: noSak ?? this.noSak,
      noBBPartial: noBBPartial ?? this.noBBPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      dateUsage: dateUsage ?? this.dateUsage,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
    );
  }

  String toDebugString() {
    final part = (noBBPartial ?? '').trim();
    final base = (noBahanBaku ?? '-').trim();
    final pal = noPallet;
    final title = part.isNotEmpty
        ? part
        : (pal == null || pal == 0 ? base : '$base-$pal');
    final tag = isPartialRow ? '[BB•PART]' : '[BB]';
    return '$tag $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}