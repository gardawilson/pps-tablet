import 'package:intl/intl.dart';

class BongkarSusun {
  final String noBongkarSusun;
  final DateTime? tanggal;
  final int idUsername;
  final String? note;

  // ⬅️ baru: diambil dari kolom Username (join MstUsername)
  final String? username;

  const BongkarSusun({
    required this.noBongkarSusun,
    required this.tanggal,
    required this.idUsername,
    this.note,
    this.username,
  });

  // ---------- tolerant parsers (sama pola dengan BrokerProduction) ----------

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

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.tryParse(v);
      } catch (_) {
        return null;
      }
    }
    if (v is int) {
      // misal dikirim sebagai millisecondsSinceEpoch
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return null;
  }

  // 👇 Tetap: untuk dropdown text
  String get displayText {
    if (note == null || note!.trim().isEmpty) {
      return noBongkarSusun;
    }
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
      // ⬅️ mapping dari response: "Username": "Marissa"
      username: j['Username'] == null
          ? null
          : _asString(j['Username']),
    );
  }

  /// asDateOnly mengikuti pola BrokerProduction (yyyy-MM-dd) kalau true
  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoBongkarSusun': noBongkarSusun,
    'Tanggal': tanggal == null
        ? null
        : (asDateOnly
        ? DateFormat('yyyy-MM-dd').format(tanggal!)
        : tanggal!.toIso8601String()),
    'IdUsername': idUsername,
    'Note': note,
    // optional: kirim balik kalau mau, kalau tidak perlu bisa dihapus
    'Username': username,
  };

  String get tanggalText {
    if (tanggal == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }
}
