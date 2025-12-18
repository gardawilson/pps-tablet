// lib/features/production/shared/models/barang_jadi_item.dart

import 'model_helpers.dart';

class BarangJadiItem {
  final String? noBJ;
  final String? noBJPartial;
  final int? idJenis; // IdBJ
  final String? namaJenis;
  final DateTime? dateCreate;
  final DateTime? dateUsage;
  final String? jam;
  final int? pcs;
  final double? berat;
  final int? idWarehouse;
  final String? createBy;
  final DateTime? dateTimeCreate;
  final String? blok;
  final int? idLokasi;
  final bool? isPartial;

  /// Row dianggap "partial" jika ada kode partial ATAU flag isPartial = true
  bool get isPartialRow =>
      (noBJPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  BarangJadiItem({
    this.noBJ,
    this.noBJPartial,
    this.idJenis,
    this.namaJenis,
    this.dateCreate,
    this.dateUsage,
    this.jam,
    this.pcs,
    this.berat,
    this.idWarehouse,
    this.createBy,
    this.dateTimeCreate,
    this.blok,
    this.idLokasi,
    this.isPartial,
  });

  factory BarangJadiItem.fromJson(Map<String, dynamic> j) => BarangJadiItem(
    noBJ: pickS(j, ['noBJ', 'NoBJ', 'noBj', 'no_bj']),
    noBJPartial: pickS(
        j, ['noBJPartial', 'NoBJPartial', 'noBjPartial', 'no_bj_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis', 'idBJ', 'IdBJ', 'id_jenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
    dateCreate: pickDT(j, ['dateCreate', 'DateCreate', 'date_create']),
    dateUsage: pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
    jam: pickS(j, ['jam', 'Jam']),
    pcs: pickI(j, ['pcs', 'Pcs']),
    berat: pickD(j, ['berat', 'Berat']),
    idWarehouse: pickI(j, ['idWarehouse', 'IdWarehouse', 'id_warehouse']),
    createBy: pickS(j, ['createBy', 'CreateBy', 'create_by']),
    dateTimeCreate:
    pickDT(j, ['dateTimeCreate', 'DateTimeCreate', 'date_time_create']),
    blok: pickS(j, ['blok', 'Blok']),
    idLokasi: pickI(j, ['idLokasi', 'IdLokasi', 'id_lokasi']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
  );

  BarangJadiItem copyWith({
    String? noBJ,
    String? noBJPartial,
    int? idJenis,
    String? namaJenis,
    DateTime? dateCreate,
    DateTime? dateUsage,
    String? jam,
    int? pcs,
    double? berat,
    int? idWarehouse,
    String? createBy,
    DateTime? dateTimeCreate,
    String? blok,
    int? idLokasi,
    bool? isPartial,
  }) {
    return BarangJadiItem(
      noBJ: noBJ ?? this.noBJ,
      noBJPartial: noBJPartial ?? this.noBJPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
      dateCreate: dateCreate ?? this.dateCreate,
      dateUsage: dateUsage ?? this.dateUsage,
      jam: jam ?? this.jam,
      pcs: pcs ?? this.pcs,
      berat: berat ?? this.berat,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      isPartial: isPartial ?? this.isPartial,
    );
  }

  String toDebugString() {
    final part = (noBJPartial ?? '').trim();
    final base = (noBJ ?? '-').trim();
    final title = part.isNotEmpty ? part : base;
    final tag = isPartialRow ? '[BJ•PART]' : '[BJ]';
    return '$tag $title • ${pcs ?? 0} pcs • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}