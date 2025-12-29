import 'package:intl/intl.dart';

class BongkarSusun {
  final String noBongkarSusun;
  final DateTime? tanggal;
  final int idUsername;
  final String? note;

  // join MstUsername
  final String? username;

  // ✅ NEW: tutup transaksi flags
  final DateTime? lastClosedDate; // date only
  final bool isLocked;

  const BongkarSusun({
    required this.noBongkarSusun,
    required this.tanggal,
    required this.idUsername,
    this.note,
    this.username,

    // ✅ NEW
    this.lastClosedDate,
    this.isLocked = false,
  });

  // ---------- tolerant parsers ----------
  static String _asString(dynamic v) => v?.toString() ?? '';

  static int _asIntRequired(dynamic v, {int fallback = 0}) {
    final r = _asInt(v);
    return r ?? fallback;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is double) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return fallback;
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  // untuk dropdown text
  String get displayText {
    if (note == null || note!.trim().isEmpty) return noBongkarSusun;
    return '$noBongkarSusun | $note';
  }

  factory BongkarSusun.fromJson(Map<String, dynamic> j) {
    return BongkarSusun(
      noBongkarSusun: _asString(j['NoBongkarSusun']),
      tanggal: _asDateTime(j['Tanggal']),
      idUsername: _asIntRequired(j['IdUsername']),
      note: (j['Note'] == null || j['Note'].toString().trim().isEmpty)
          ? null
          : _asString(j['Note']),
      username: j['Username'] == null ? null : _asString(j['Username']),

      // ✅ NEW
      lastClosedDate: _asDateTime(j['LastClosedDate']),
      isLocked: _asBool(j['IsLocked']),
    );
  }

  /// asDateOnly: yyyy-MM-dd kalau true
  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoBongkarSusun': noBongkarSusun,
    'Tanggal': tanggal == null
        ? null
        : (asDateOnly
        ? DateFormat('yyyy-MM-dd').format(tanggal!)
        : tanggal!.toIso8601String()),
    'IdUsername': idUsername,
    'Note': note,
    'Username': username,

    // biasanya read-only, tidak perlu dikirim balik
    // 'LastClosedDate': lastClosedDate?.toIso8601String(),
    // 'IsLocked': isLocked,
  };

  String get tanggalText {
    if (tanggal == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }

  // ✅ Optional untuk UI
  String get lockInfoText {
    if (!isLocked) return '';
    if (lastClosedDate == null) return 'Locked';
    final d = DateFormat('dd MMM yyyy', 'id_ID').format(lastClosedDate!.toLocal());
    return 'Locked (<= $d)';
  }
}
