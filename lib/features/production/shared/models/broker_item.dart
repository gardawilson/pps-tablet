// lib/features/production/shared/models/broker_item.dart

import 'model_helpers.dart';

class BrokerItem {
  final String? noBroker;
  final int? noSak;
  final String? noBrokerPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  /// Row dianggap "partial" jika ada kode partial ATAU flag isPartial = true
  bool get isPartialRow =>
      (noBrokerPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  BrokerItem({
    this.noBroker,
    this.noSak,
    this.noBrokerPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory BrokerItem.fromJson(Map<String, dynamic> j) => BrokerItem(
    noBroker: pickS(j, ['noBroker', 'NoBroker', 'no_broker']),
    noSak: pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noBrokerPartial: pickS(
        j, ['noBrokerPartial', 'NoBrokerPartial', 'no_broker_partial']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis']),
  );

  BrokerItem copyWith({
    String? noBroker,
    int? noSak,
    String? noBrokerPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    int? idJenis,
    String? namaJenis,
  }) {
    return BrokerItem(
      noBroker: noBroker ?? this.noBroker,
      noSak: noSak ?? this.noSak,
      noBrokerPartial: noBrokerPartial ?? this.noBrokerPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
    );
  }

  String toDebugString() {
    final part = (noBrokerPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noBroker ?? '-');
    final tag = isPartialRow ? '[BROKER•PART]' : '[BROKER]';
    return '$tag $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}