// lib/features/production/shared/models/furniture_wip_item.dart

import 'model_helpers.dart';

class FurnitureWipItem {
  final String? noFurnitureWIP;
  final String? noFurnitureWIPPartial;
  final DateTime? dateCreate;
  final String? jam;
  final int? pcs;
  final int? idJenis; // IDFurnitureWIP
  final String? namaJenis;
  final double? berat;
  final DateTime? dateUsage;
  final int? idWarehouse;
  final int? idWarna;
  final String? createBy;
  final DateTime? dateTimeCreate;
  final String? blok;
  final int? idLokasi;
  final bool? isPartial;

  /// Row dianggap "partial" jika ada kode partial ATAU flag isPartial = true
  bool get isPartialRow =>
      (noFurnitureWIPPartial?.trim().isNotEmpty ?? false) ||
          (isPartial == true);

  FurnitureWipItem({
    this.noFurnitureWIP,
    this.noFurnitureWIPPartial,
    this.dateCreate,
    this.jam,
    this.pcs,
    this.idJenis,
    this.namaJenis,
    this.berat,
    this.dateUsage,
    this.idWarehouse,
    this.idWarna,
    this.createBy,
    this.dateTimeCreate,
    this.blok,
    this.idLokasi,
    this.isPartial,
  });

  factory FurnitureWipItem.fromJson(Map<String, dynamic> j) =>
      FurnitureWipItem(
        noFurnitureWIP: pickS(j, [
          'noFurnitureWIP',
          'noFurnitureWip',
          'NoFurnitureWIP'
        ]),
        noFurnitureWIPPartial: pickS(j, [
          'noFurnitureWIPPartial',
          'NoFurnitureWIPPartial',
          'no_furniture_wip_partial'
        ]),
        dateCreate: pickDT(j, ['dateCreate', 'DateCreate', 'date_create']),
        jam: pickS(j, ['jam', 'Jam']),
        pcs: pickI(j, ['pcs', 'Pcs']),
        idJenis: pickI(j, ['idJenis', 'IdJenis', 'id_jenis']),
        namaJenis: pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
        berat: pickD(j, ['berat', 'Berat']),
        dateUsage: pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
        idWarehouse: pickI(j, ['idWarehouse', 'IdWarehouse', 'id_warehouse']),
        idWarna: pickI(j, ['idWarna', 'IdWarna', 'id_warna']),
        createBy: pickS(j, ['createBy', 'CreateBy', 'create_by']),
        dateTimeCreate:
        pickDT(j, ['dateTimeCreate', 'DateTimeCreate', 'date_time_create']),
        blok: pickS(j, ['blok', 'Blok']),
        idLokasi: pickI(j, ['idLokasi', 'IdLokasi', 'id_lokasi']),
        isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
      );

  FurnitureWipItem copyWith({
    String? noFurnitureWIP,
    String? noFurnitureWIPPartial,
    DateTime? dateCreate,
    String? jam,
    int? pcs,
    int? idJenis,
    String? namaJenis,
    double? berat,
    DateTime? dateUsage,
    int? idWarehouse,
    int? idWarna,
    String? createBy,
    DateTime? dateTimeCreate,
    String? blok,
    int? idLokasi,
    bool? isPartial,
  }) {
    return FurnitureWipItem(
      noFurnitureWIP: noFurnitureWIP ?? this.noFurnitureWIP,
      noFurnitureWIPPartial:
      noFurnitureWIPPartial ?? this.noFurnitureWIPPartial,
      dateCreate: dateCreate ?? this.dateCreate,
      jam: jam ?? this.jam,
      pcs: pcs ?? this.pcs,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
      berat: berat ?? this.berat,
      dateUsage: dateUsage ?? this.dateUsage,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      idWarna: idWarna ?? this.idWarna,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      isPartial: isPartial ?? this.isPartial,
    );
  }

  String toDebugString() {
    final part = (noFurnitureWIPPartial ?? '').trim();
    final base = (noFurnitureWIP ?? '-').trim();
    final title = part.isNotEmpty ? part : base;
    final tag = isPartialRow ? '[FW•PART]' : '[FW]';
    return '$tag $title • ${pcs ?? 0} pcs • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}