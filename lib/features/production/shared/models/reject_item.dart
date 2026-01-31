// lib/features/production/shared/models/reject_item.dart

import '../../../../core/utils/model_helpers.dart';

class RejectItem {
  final String? noReject;
  final String? noRejectPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  bool get isPartialRow =>
      (noRejectPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  RejectItem({
    this.noReject,
    this.noRejectPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory RejectItem.fromJson(Map<String, dynamic> j) => RejectItem(
    noReject: pickS(j, ['noReject', 'NoReject', 'no_reject']),
    noRejectPartial: pickS(
        j, ['noRejectPartial', 'NoRejectPartial', 'no_reject_partial']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis']),
  );

  RejectItem copyWith({
    String? noReject,
    String? noRejectPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    int? idJenis,
    String? namaJenis,
  }) {
    return RejectItem(
      noReject: noReject ?? this.noReject,
      noRejectPartial: noRejectPartial ?? this.noRejectPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
    );
  }

  String toDebugString() {
    final part = (noRejectPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noReject ?? '-');
    final tag = isPartialRow ? '[REJ•PART]' : '[REJ]';
    return '$tag $title • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}
