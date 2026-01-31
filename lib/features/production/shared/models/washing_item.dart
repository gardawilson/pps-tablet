// lib/features/production/shared/models/washing_item.dart

import '../../../../core/utils/model_helpers.dart';

class WashingItem {
  final String? noWashing;
  final int? noSak;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  WashingItem({
    this.noWashing,
    this.noSak,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory WashingItem.fromJson(Map<String, dynamic> j) => WashingItem(
    noWashing: pickS(j, ['noWashing', 'NoWashing', 'no_washing']),
    noSak: pickI(j, ['noSak', 'NoSak', 'no_sak']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis']),
  );

  String toDebugString() =>
      '[WASH] ${noWashing ?? '-'} • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
}