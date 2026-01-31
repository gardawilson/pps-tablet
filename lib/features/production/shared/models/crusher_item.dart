// lib/features/production/shared/models/crusher_item.dart

import '../../../../core/utils/model_helpers.dart';

class CrusherItem {
  final String? noCrusher;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  CrusherItem({
    this.noCrusher,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory CrusherItem.fromJson(Map<String, dynamic> j) => CrusherItem(
    noCrusher: pickS(j, ['noCrusher', 'NoCrusher', 'no_crusher']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis']),
  );

  String toDebugString() =>
      '[CRUSH] ${noCrusher ?? '-'} • ${(berat ?? 0).toStringAsFixed(2)}kg';
}