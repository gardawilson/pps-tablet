// lib/features/production/shared/models/bonggolan_item.dart

import 'model_helpers.dart';

class BonggolanItem {
  final String? noBonggolan;     // M.0000000003
  final DateTime? dateCreate;
  final String? namaJenis;
  final int? idBonggolan;
  final int? idWarehouse;
  final DateTime? dateUsage;
  final double? berat;
  final int? idStatus;
  final String? blok;
  final int? idLokasi;
  final String? createBy;
  final DateTime? dateTimeCreate;

  BonggolanItem({
    this.noBonggolan,
    this.dateCreate,
    this.namaJenis,
    this.idBonggolan,
    this.idWarehouse,
    this.dateUsage,
    this.berat,
    this.idStatus,
    this.blok,
    this.idLokasi,
    this.createBy,
    this.dateTimeCreate,
  });

  factory BonggolanItem.fromJson(Map<String, dynamic> j) => BonggolanItem(
    noBonggolan: pickS(j, ['noBonggolan', 'NoBonggolan', 'no_bonggolan']),
    dateCreate: pickDT(j, ['dateCreate', 'DateCreate', 'date_create']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
    idBonggolan: pickI(j, ['idBonggolan', 'IdBonggolan', 'id_bonggolan']),
    idWarehouse: pickI(j, ['idWarehouse', 'IdWarehouse', 'id_warehouse']),
    dateUsage: pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
    berat: pickD(j, ['berat', 'Berat']),
    idStatus: pickI(j, ['idStatus', 'IdStatus', 'id_status']),
    blok: pickS(j, ['blok', 'Blok']),
    idLokasi: pickI(j, ['idLokasi', 'IdLokasi', 'id_lokasi']),
    createBy: pickS(j, ['createBy', 'CreateBy', 'create_by']),
    dateTimeCreate: pickDT(j, ['dateTimeCreate', 'DateTimeCreate', 'date_time_create']),
  );

  String toDebugString() =>
      '[BONGGOL] ${noBonggolan ?? '-'} • ${(berat ?? 0).toStringAsFixed(2)}kg';
}