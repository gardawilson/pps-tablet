// lib/features/shared/inject_production/model/inject_production_model.dart

class InjectProduction {
  final String noProduksi;

  final DateTime? tglProduksi;

  final int idMesin;
  final String namaMesin;

  final int idOperator;
  final String namaOperator;

  /// Inject: Jam = INT (hour only)
  final int jam;

  final int shift;

  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;

  final int jmlhAnggota;
  final int hadir;

  final num? hourMeter;

  final int? idCetakan;
  final int? idWarna;

  final bool enableOffset;
  final num? offsetCurrent;
  final num? offsetNext;

  final int? idFurnitureMaterial;

  final num? beratProdukHasilTimbang;

  /// ✅ normalized for UI: always "HH:mm" (or null)
  final String? hourStart;
  final String? hourEnd;

  /// date-only (or null)
  final DateTime? lastClosedDate;

  final bool isLocked;

  const InjectProduction({
    required this.noProduksi,
    required this.tglProduksi,
    required this.idMesin,
    required this.namaMesin,
    required this.idOperator,
    required this.namaOperator,
    required this.jam,
    required this.shift,
    this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    required this.jmlhAnggota,
    required this.hadir,
    this.hourMeter,
    this.idCetakan,
    this.idWarna,
    required this.enableOffset,
    this.offsetCurrent,
    this.offsetNext,
    this.idFurnitureMaterial,
    this.beratProdukHasilTimbang,
    this.hourStart,
    this.hourEnd,
    this.lastClosedDate,
    required this.isLocked,
  });

  // -------------------- tolerant parsers --------------------

  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'y' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'n' || s == 'no') return false;
    }
    return fallback;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    return null;
  }

  /// ✅ normalize many time formats into "HH:mm" for UI + validators
  /// Accepts:
  /// - "08:00"
  /// - "08:00:00"
  /// - ISO "1970-01-01T08:00:00.000Z"
  /// - DateTime
  static String? _asHHmm(dynamic v) {
    if (v == null) return null;

    if (v is DateTime) {
      final hh = v.hour.toString().padLeft(2, '0');
      final mm = v.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    // "08:00"
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return s;

    // "08:00:00" -> "08:00"
    final m1 = RegExp(r'^(\d{2}:\d{2}):\d{2}$').firstMatch(s);
    if (m1 != null) return m1.group(1)!;

    // ISO "...T08:00:00.000Z" -> "08:00"
    final m2 = RegExp(r'T(\d{2}:\d{2})').firstMatch(s);
    if (m2 != null) return m2.group(1)!;

    // fallback parse DateTime string
    final dt = DateTime.tryParse(s);
    if (dt != null) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return null;
  }

  factory InjectProduction.fromJson(Map<String, dynamic> j) {
    return InjectProduction(
      noProduksi: _asString(j['NoProduksi']),
      tglProduksi: _asDateTime(j['TglProduksi']),

      idMesin: _asInt(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),

      idOperator: _asInt(j['IdOperator']),
      namaOperator: _asString(j['NamaOperator']),

      jam: _asInt(j['Jam']),
      shift: _asInt(j['Shift']),

      createBy: j['CreateBy']?.toString(),
      checkBy1: j['CheckBy1']?.toString(),
      checkBy2: j['CheckBy2']?.toString(),
      approveBy: j['ApproveBy']?.toString(),

      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),

      hourMeter: _asNum(j['HourMeter']),
      idCetakan: (j['IdCetakan'] as num?)?.toInt(),
      idWarna: (j['IdWarna'] as num?)?.toInt(),

      enableOffset: _asBool(j['EnableOffset'], fallback: false),
      offsetCurrent: _asNum(j['OffsetCurrent']),
      offsetNext: _asNum(j['OffsetNext']),

      idFurnitureMaterial: (j['IdFurnitureMaterial'] as num?)?.toInt(),
      beratProdukHasilTimbang: _asNum(j['BeratProdukHasilTimbang']),

      // ✅ normalized to "HH:mm"
      hourStart: _asHHmm(j['HourStart']),
      hourEnd: _asHHmm(j['HourEnd']),

      lastClosedDate: _asDateTime(j['LastClosedDate']),
      isLocked: _asBool(j['IsLocked'], fallback: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoProduksi': noProduksi,
      'TglProduksi': tglProduksi?.toIso8601String(),

      'IdMesin': idMesin,
      'NamaMesin': namaMesin,
      'IdOperator': idOperator,
      'NamaOperator': namaOperator,

      'Jam': jam,
      'Shift': shift,

      'CreateBy': createBy,
      'CheckBy1': checkBy1,
      'CheckBy2': checkBy2,
      'ApproveBy': approveBy,

      'JmlhAnggota': jmlhAnggota,
      'Hadir': hadir,

      'HourMeter': hourMeter,
      'IdCetakan': idCetakan,
      'IdWarna': idWarna,

      'EnableOffset': enableOffset,
      'OffsetCurrent': offsetCurrent,
      'OffsetNext': offsetNext,

      'IdFurnitureMaterial': idFurnitureMaterial,
      'BeratProdukHasilTimbang': beratProdukHasilTimbang,

      // ✅ store as HH:mm (UI-friendly); submit layer can convert to HH:mm:ss
      'HourStart': hourStart,
      'HourEnd': hourEnd,

      'LastClosedDate': lastClosedDate?.toIso8601String(),
      'IsLocked': isLocked,
    };
  }

  /// Optional helper for UI
  String get jamLabel => jam <= 0 ? '-' : '${jam.toString().padLeft(2, '0')}:00';

  bool get hasHourRange =>
      (hourStart != null && hourStart!.trim().isNotEmpty) &&
          (hourEnd != null && hourEnd!.trim().isNotEmpty);
}
