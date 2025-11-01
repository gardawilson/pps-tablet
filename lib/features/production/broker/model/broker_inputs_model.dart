// lib/features/broker/model/broker_inputs_model.dart
import 'dart:convert';

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase().trim();
  if (s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y') return true;
  if (s == '0' || s == 'false' || s == 'f' || s == 'no' || s == 'n') return false;
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/* ===================== ITEM MODELS ===================== */

// broker: main only (NoBroker + NoSak), no partial concept
class BrokerItem {
  final String? noBroker;
  final int? noSak;
  final double? berat;
  final double? beratAct;
  final bool? isPartial; // from source, may exist but not the same as "partial-row"

  BrokerItem({
    this.noBroker,
    this.noSak,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory BrokerItem.fromJson(Map<String, dynamic> j) => BrokerItem(
    noBroker: _asString(j['noBroker']),
    noSak: _asInt(j['noSak']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// bb: main (noBahanBaku,noPallet,noSak,berat,beratAct,isPartial) OR partial ({noBBPartial, noBahanBaku,noPallet,noSak,berat})
class BbItem {
  final String? noBahanBaku;
  final int? noPallet;
  final int? noSak;

  // present only for partial row
  final String? noBBPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  bool get isPartialRow => noBBPartial != null;

  BbItem({
    this.noBahanBaku,
    this.noPallet,
    this.noSak,
    this.noBBPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory BbItem.fromJson(Map<String, dynamic> j) => BbItem(
    noBahanBaku: _asString(j['noBahanBaku']),
    noPallet: _asInt(j['noPallet']),
    noSak: _asInt(j['noSak']),
    noBBPartial: _asString(j['noBBPartial']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// washing: (NoWashing + NoSak) no partial concept
class WashingItem {
  final String? noWashing;
  final int? noSak;
  final double? berat;
  final double? beratAct; // usually null
  final bool? isPartial;  // usually null

  WashingItem({
    this.noWashing,
    this.noSak,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory WashingItem.fromJson(Map<String, dynamic> j) => WashingItem(
    noWashing: _asString(j['noWashing']),
    noSak: _asInt(j['noSak']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// crusher: (NoCrusher), no partial concept
class CrusherItem {
  final String? noCrusher;
  final double? berat;
  final double? beratAct; // usually null
  final bool? isPartial;  // usually null

  CrusherItem({
    this.noCrusher,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory CrusherItem.fromJson(Map<String, dynamic> j) => CrusherItem(
    noCrusher: _asString(j['noCrusher']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// gilingan: main (NoGilingan, ...) OR partial ({noGilinganPartial, noGilingan, berat})
class GilinganItem {
  final String? noGilingan;

  // partial row only
  final String? noGilinganPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  bool get isPartialRow => noGilinganPartial != null;

  GilinganItem({
    this.noGilingan,
    this.noGilinganPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory GilinganItem.fromJson(Map<String, dynamic> j) => GilinganItem(
    noGilingan: _asString(j['noGilingan']),
    noGilinganPartial: _asString(j['noGilinganPartial']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// mixer: main (NoMixer + NoSak) OR partial ({noMixerPartial, noMixer, noSak, berat})
class MixerItem {
  final String? noMixer;
  final int? noSak;

  // partial row only
  final String? noMixerPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  bool get isPartialRow => noMixerPartial != null;

  MixerItem({
    this.noMixer,
    this.noSak,
    this.noMixerPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory MixerItem.fromJson(Map<String, dynamic> j) => MixerItem(
    noMixer: _asString(j['noMixer']),
    noSak: _asInt(j['noSak']),
    noMixerPartial: _asString(j['noMixerPartial']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

// reject: main (NoReject) OR partial ({noRejectPartial, noReject, berat})
class RejectItem {
  final String? noReject;

  // partial row only
  final String? noRejectPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  bool get isPartialRow => noRejectPartial != null;

  RejectItem({
    this.noReject,
    this.noRejectPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
  });

  factory RejectItem.fromJson(Map<String, dynamic> j) => RejectItem(
    noReject: _asString(j['noReject']),
    noRejectPartial: _asString(j['noRejectPartial']),
    berat: _asDouble(j['berat']),
    beratAct: _asDouble(j['beratAct']),
    isPartial: _asBool(j['isPartial']),
  );
}

/* ===================== ROOT ===================== */

class BrokerInputs {
  final List<BrokerItem> broker;
  final List<BbItem> bb;
  final List<WashingItem> washing;
  final List<CrusherItem> crusher;
  final List<GilinganItem> gilingan;
  final List<MixerItem> mixer;
  final List<RejectItem> reject;

  final Map<String, int> summary;

  BrokerInputs({
    required this.broker,
    required this.bb,
    required this.washing,
    required this.crusher,
    required this.gilingan,
    required this.mixer,
    required this.reject,
    required this.summary,
  });

  factory BrokerInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, _asInt(v) ?? 0));
    }

    return BrokerInputs(
      broker:   _listOf(j['broker'],   (m) => BrokerItem.fromJson(m)),
      bb:       _listOf(j['bb'],       (m) => BbItem.fromJson(m)),
      washing:  _listOf(j['washing'],  (m) => WashingItem.fromJson(m)),
      crusher:  _listOf(j['crusher'],  (m) => CrusherItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      mixer:    _listOf(j['mixer'],    (m) => MixerItem.fromJson(m)),
      reject:   _listOf(j['reject'],   (m) => RejectItem.fromJson(m)),
      summary:  _toSummary(j['summary']),
    );
  }

  // Optional: quick totals (including partial rows) you can call in UI
  double totalBeratBb()       => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() => gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratMixer()    => mixer.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratReject()   => reject.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBroker()   => broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratWashing()  => washing.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratCrusher()  => crusher.fold(0.0, (s, it) => s + (it.berat ?? 0));
}
