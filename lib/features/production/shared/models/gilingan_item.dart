// lib/features/production/shared/models/gilingan_item.dart

import 'model_helpers.dart';

class GilinganItem {
  final String? noGilingan;
  final String? noGilinganPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;
  final DateTime? dateCreate;
  final DateTime? dateUsage;

  /// Row dianggap partial jika ada kode partial ATAU isPartial = true
  bool get isPartialRow =>
      (noGilinganPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  GilinganItem({
    this.noGilingan,
    this.noGilinganPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
    this.dateCreate,
    this.dateUsage,
  });

  factory GilinganItem.fromJson(Map<String, dynamic> j) => GilinganItem(
    noGilingan: pickS(j, ['noGilingan', 'NoGilingan', 'no_gilingan']),
    noGilinganPartial: pickS(j,
        ['noGilinganPartial', 'NoGilinganPartial', 'no_gilingan_partial']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis', 'id_jenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
    dateCreate: pickDT(j, ['dateCreate', 'DateCreate', 'date_create']),
    dateUsage: pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
  );

  GilinganItem copyWith({
    String? noGilingan,
    String? noGilinganPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    int? idJenis,
    String? namaJenis,
    DateTime? dateCreate,
    DateTime? dateUsage,
  }) {
    return GilinganItem(
      noGilingan: noGilingan ?? this.noGilingan,
      noGilinganPartial: noGilinganPartial ?? this.noGilinganPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
      dateCreate: dateCreate ?? this.dateCreate,
      dateUsage: dateUsage ?? this.dateUsage,
    );
  }

  String toDebugString() {
    final part = (noGilinganPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noGilingan ?? '-');
    final tag = isPartialRow ? '[GIL•PART]' : '[GIL]';
    return '$tag $title • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}