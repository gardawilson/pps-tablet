// lib/features/shared/washing_production/model/washing_production_model.dart
import 'package:intl/intl.dart';

class WashingProduction {
  final String noProduksi;
  final int idOperator;
  final String namaOperator;
  final int idMesin;
  final String namaMesin;
  final DateTime? tglProduksi;
  final int jamKerja;
  final int shift;
  final String createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int? jmlhAnggota;
  final int? hadir;
  final int? hourMeter;
  final String? hourStart; // "HH:mm"
  final String? hourEnd;   // "HH:mm"

  // ✅ Tutup transaksi flags
  final bool isLocked;            // dari SQL: IsLocked (bit)
  final DateTime? lastClosedDate; // dari SQL: LastClosedDate (date)

  const WashingProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.namaOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.tglProduksi,
    required this.jamKerja,
    required this.shift,
    required this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.hourStart,
    this.hourEnd,
    required this.isLocked,
    this.lastClosedDate,
  });

  // ---------- Tolerant parsers ----------
  static String _asString(dynamic v) => v?.toString() ?? '';

  static int _asIntRequired(dynamic v, {int fallback = 0}) {
    final r = _asInt(v);
    return r ?? fallback;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
      if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
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
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return null;
  }

  // Normalize MSSQL TIME string "HH:mm:ss" to "HH:mm"
  static String? _asTimeHHmm(dynamic v) {
    if (v == null) return null;

    // If driver mapped TIME to DateTime (often 1970-01-01 + time)
    if (v is DateTime) {
      return DateFormat('HH:mm').format(v.toLocal());
    }

    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;

      final asDt = DateTime.tryParse(s);
      if (asDt != null) {
        return DateFormat('HH:mm').format(asDt.toLocal());
      }

      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
      if (m != null) {
        final hh = m.group(1)!.padLeft(2, '0');
        final mm = m.group(2)!;
        return '$hh:$mm';
      }
    }

    return null;
  }

  factory WashingProduction.fromJson(Map<String, dynamic> j) {
    final hm = _asDouble(j['HourMeter']); // kadang decimal

    return WashingProduction(
      noProduksi: _asString(j['NoProduksi']),
      idOperator: _asIntRequired(j['IdOperator']),
      namaOperator: _asString(j['NamaOperator']),
      idMesin: _asIntRequired(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),
      tglProduksi: _asDateTime(j['TglProduksi']),
      jamKerja: _asIntRequired(j['JamKerja']),
      shift: _asIntRequired(j['Shift']),
      createBy: _asString(j['CreateBy']),
      checkBy1: (j['CheckBy1'] == null || _asString(j['CheckBy1']).trim().isEmpty)
          ? null
          : _asString(j['CheckBy1']),
      checkBy2: (j['CheckBy2'] == null || _asString(j['CheckBy2']).trim().isEmpty)
          ? null
          : _asString(j['CheckBy2']),
      approveBy: (j['ApproveBy'] == null || _asString(j['ApproveBy']).trim().isEmpty)
          ? null
          : _asString(j['ApproveBy']),
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: hm?.round(), // kalau kamu mau tetap int
      // kalau mau simpan double, ganti field hourMeter jadi double? di model
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),

      // ✅ new fields
      isLocked: _asBool(j['IsLocked'], fallback: false),
      lastClosedDate: _asDateTime(j['LastClosedDate']),
    );
  }

  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoProduksi': noProduksi,
    'IdOperator': idOperator,
    'NamaOperator': namaOperator,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'TglProduksi': tglProduksi == null
        ? null
        : (asDateOnly
        ? DateFormat('yyyy-MM-dd').format(tglProduksi!)
        : tglProduksi!.toIso8601String()),
    'JamKerja': jamKerja,
    'Shift': shift,
    'CreateBy': createBy,
    'CheckBy1': checkBy1,
    'CheckBy2': checkBy2,
    'ApproveBy': approveBy,
    'JmlhAnggota': jmlhAnggota,
    'Hadir': hadir,
    'HourMeter': hourMeter,
    'HourStart': hourStart,
    'HourEnd': hourEnd,

    // biasanya tidak perlu dikirim ke server,
    // tapi aman kalau disertakan untuk cache/local state
    'IsLocked': isLocked,
    'LastClosedDate': lastClosedDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(lastClosedDate!),
  };

  // ---------- Display helpers ----------
  String get tglProduksiTextShort {
    if (tglProduksi == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
    // NOTE: kalau server kirim "2025-12-28T00:00:00.000Z", toLocal bisa jadi jam 07:00.
    // Kalau kamu ingin benar-benar date-only tampilan, bisa format dari UTC (lihat catatan di bawah).
  }

  String get tglProduksiTextFull {
    if (tglProduksi == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get hourRangeText {
    if ((hourStart == null || hourStart!.isEmpty) &&
        (hourEnd == null || hourEnd!.isEmpty)) return '';
    return '${hourStart ?? '--:--'} - ${hourEnd ?? '--:--'}';
  }

  // ✅ helper untuk UI: badge tutup transaksi
  String get lockBadgeText {
    if (!isLocked) return '';
    if (lastClosedDate == null) return 'Tutup Transaksi';
    final s = DateFormat('dd MMM yyyy', 'id_ID').format(lastClosedDate!.toLocal());
    return 'Tutup s/d $s';
  }

  bool get canEdit => !isLocked;
  bool get canDelete => !isLocked;
  bool get canManageInputs => !isLocked;

  // (Opsional) Kalau kamu mau tampilan date-only yang tidak pernah “geser”
  // gunakan UTC (karena server kamu sudah normalize date-only).
  String get tglProduksiTextShortUtc {
    if (tglProduksi == null) return '';
    final d = tglProduksi!.toUtc();
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  }
}
