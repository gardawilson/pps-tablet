// lib/features/broker/model/broker_inputs_model.dart
import 'dart:convert';

/* ===================== PARSER HELPERS (tolerant keys) ===================== */

String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase().trim();
  if (s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y') return true;
  if (s == '0' || s == 'false' || s == 'f' || s == 'no' || s == 'n') return false;
  return null;
}

/// Ambil string dari beberapa kandidat key
String? _pickS(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = _asString(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

int? _pickI(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = _asInt(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

double? _pickD(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = _asDouble(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

bool? _pickB(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = _asBool(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

/* ===================== ITEM MODELS ===================== */

class BrokerItem {
  final String? noBroker;
  final int? noSak;
  final String? noBrokerPartial;  // TAMBAHKAN INI untuk kode partial
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
    this.noBrokerPartial,  // TAMBAHKAN INI
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory BrokerItem.fromJson(Map<String, dynamic> j) => BrokerItem(
    noBroker: _pickS(j, ['noBroker', 'NoBroker', 'no_broker']),
    noSak: _pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noBrokerPartial: _pickS(j, ['noBrokerPartial', 'NoBrokerPartial', 'no_broker_partial']), // TAMBAHKAN
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis']),
  );

  // TAMBAHKAN copyWith method
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

  // UPDATE toDebugString method
  String toDebugString() {
    final part = (noBrokerPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noBroker ?? '-');
    final tag = isPartialRow ? '[BROKER•PART]' : '[BROKER]';
    return '$tag $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}

class BbItem {
  final String? noBahanBaku;
  final int? noPallet;
  final int? noSak;

  /// partial row only (kode partial gabungan, kalau ada)
  final String? noBBPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  /// waktu pemakaian (bila sudah terpakai); nullable
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
    noBahanBaku: _pickS(j, ['noBahanBaku', 'NoBahanBaku', 'no_bahan_baku']),
    noPallet: _pickI(j, ['noPallet', 'NoPallet', 'no_pallet']),
    noSak: _pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noBBPartial: _pickS(j, ['noBBPartial', 'NoBBPartial', 'no_bb_partial']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    dateUsage: _pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis', 'id_jenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
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

/// ---- helper kecil untuk DateTime (aman null) ----
/// Mencoba baca ISO string (e.g. "2025-11-13T07:10:00Z") atau epoch (ms/s).
DateTime? _pickDT(Map<String, dynamic> j, List<String> keys) {
  dynamic v;
  for (final k in keys) {
    if (j.containsKey(k)) {
      v = j[k];
      break;
    }
  }
  if (v == null) return null;

  if (v is DateTime) return v;

  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    // fallback angka dalam string
    final maybeNum = num.tryParse(s);
    if (maybeNum != null) {
      final n = maybeNum.toInt();
      // deteksi ms vs s (>= 10^12 kita anggap ms)
      return DateTime.fromMillisecondsSinceEpoch(n >= 1000000000000 ? n : n * 1000, isUtc: true);
    }
    return null;
  }

  if (v is num) {
    final n = v.toInt();
    return DateTime.fromMillisecondsSinceEpoch(n >= 1000000000000 ? n : n * 1000, isUtc: true);
  }

  return null;
}


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
    noWashing: _pickS(j, ['noWashing', 'NoWashing', 'no_washing']),
    noSak: _pickI(j, ['noSak', 'NoSak', 'no_sak']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis']),
  );

  String toDebugString() =>
      '[WASH] ${noWashing ?? '-'} • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
}

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
    noCrusher: _pickS(j, ['noCrusher', 'NoCrusher', 'no_crusher']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis']),
  );

  String toDebugString() =>
      '[CRUSH] ${noCrusher ?? '-'} • ${(berat ?? 0).toStringAsFixed(2)}kg';
}

class GilinganItem {
  final String? noGilingan;
  final String? noGilinganPartial;

  final double? berat;
  final double? beratAct;
  final bool? isPartial;

  final int? idJenis;
  final String? namaJenis;

  /// waktu dibuat & dipakai (nullable)
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
    noGilingan: _pickS(j, ['noGilingan', 'NoGilingan', 'no_gilingan']),
    noGilinganPartial: _pickS(
        j, ['noGilinganPartial', 'NoGilinganPartial', 'no_gilingan_partial']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis', 'id_jenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis', 'nama_jenis']),
    dateCreate: _pickDT(j, ['dateCreate', 'DateCreate', 'date_create']),
    dateUsage: _pickDT(j, ['dateUsage', 'DateUsage', 'date_usage']),
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

class MixerItem {
  final String? noMixer;
  final int? noSak;
  final String? noMixerPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  bool get isPartialRow => (noMixerPartial?.trim().isNotEmpty ?? false);

  MixerItem({
    this.noMixer,
    this.noSak,
    this.noMixerPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory MixerItem.fromJson(Map<String, dynamic> j) => MixerItem(
    noMixer: _pickS(j, ['noMixer', 'NoMixer', 'no_mixer']),
    noSak: _pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noMixerPartial:
    _pickS(j, ['noMixerPartial', 'NoMixerPartial', 'no_mixer_partial']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis']),
  );

  MixerItem copyWith({
    String? noMixer,
    int? noSak,
    String? noMixerPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    int? idJenis,
    String? namaJenis,
  }) {
    return MixerItem(
      noMixer: noMixer ?? this.noMixer,
      noSak: noSak ?? this.noSak,
      noMixerPartial: noMixerPartial ?? this.noMixerPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
    );
  }

  String toDebugString() {
    final part = (noMixerPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noMixer ?? '-');
    return (part.isNotEmpty)
        ? '[MIX•PART] $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg'
        : '[MIX] $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}

class RejectItem {
  final String? noReject;
  final String? noRejectPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  bool get isPartialRow => (noRejectPartial?.trim().isNotEmpty ?? false);

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
    noReject: _pickS(j, ['noReject', 'NoReject', 'no_reject']),
    noRejectPartial:
    _pickS(j, ['noRejectPartial', 'NoRejectPartial', 'no_reject_partial']),
    berat: _pickD(j, ['berat', 'Berat']),
    beratAct: _pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: _pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: _pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: _pickS(j, ['namaJenis', 'NamaJenis']),
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
    return (part.isNotEmpty)
        ? '[REJ•PART] $title • ${(berat ?? 0).toStringAsFixed(2)}kg'
        : '[REJ] $title • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
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
      broker: _listOf(j['broker'], (m) => BrokerItem.fromJson(m)),
      bb: _listOf(j['bb'], (m) => BbItem.fromJson(m)),
      washing: _listOf(j['washing'], (m) => WashingItem.fromJson(m)),
      crusher: _listOf(j['crusher'], (m) => CrusherItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      mixer: _listOf(j['mixer'], (m) => MixerItem.fromJson(m)),
      reject: _listOf(j['reject'], (m) => RejectItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // quick totals
  double totalBeratBb() => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() => gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratMixer() => mixer.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratReject() => reject.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBroker() => broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratWashing() => washing.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratCrusher() => crusher.fold(0.0, (s, it) => s + (it.berat ?? 0));
}
