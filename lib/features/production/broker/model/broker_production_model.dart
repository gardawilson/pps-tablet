import 'package:intl/intl.dart';

class BrokerProduction {
  final String noProduksi;
  final int idOperator;
  final int idMesin;
  final String namaMesin;
  final String namaOperator;
  final DateTime? tglProduksi;
  final int jamKerja;
  final int shift;
  final String createBy;
  final int? jmlhAnggota;
  final int? hadir;
  final int? hourMeter;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;

  // ⬇️ NEW
  final String? hourStart; // "HH:mm"
  final String? hourEnd;   // "HH:mm"

  const BrokerProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.namaOperator,
    required this.tglProduksi,
    required this.jamKerja,
    required this.shift,
    required this.createBy,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    // ⬇️ NEW (optional)
    this.hourStart,
    this.hourEnd,
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
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return null;
  }

  // ⬇️ NEW: normalize MSSQL TIME to "HH:mm"
  static String? _asTimeHHmm(dynamic v) {
    if (v == null) return null;

    // If driver mapped TIME to DateTime (often 1900-01-01 + time)
    if (v is DateTime) {
      return DateFormat('HH:mm').format(v.toLocal());
    }

    // If string, accept several shapes: "HH:mm[:ss[.fff]]"
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;

      // Try parse as DateTime first (covers ISO like 1900-01-01T07:30:00)
      final asDt = DateTime.tryParse(s);
      if (asDt != null) {
        return DateFormat('HH:mm').format(asDt.toLocal());
      }

      // Fallback: extract leading HH:mm from a TIME string
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
      if (m != null) {
        final hh = m.group(1)!.padLeft(2, '0');
        final mm = m.group(2)!;
        return '$hh:$mm';
      }
    }

    return null;
  }

  factory BrokerProduction.fromJson(Map<String, dynamic> j) {
    return BrokerProduction(
      noProduksi: _asString(j['NoProduksi']),
      idOperator: _asIntRequired(j['IdOperator']),
      idMesin: _asIntRequired(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),
      namaOperator: _asString(j['NamaOperator']),
      tglProduksi: _asDateTime(j['TglProduksi']),
      jamKerja: _asIntRequired(j['JamKerja']),
      shift: _asIntRequired(j['Shift']),
      createBy: _asString(j['CreateBy']),
      checkBy1: j['CheckBy1'] == null || j['CheckBy1'] == '' ? null : _asString(j['CheckBy1']),
      checkBy2: j['CheckBy2'] == null || j['CheckBy2'] == '' ? null : _asString(j['CheckBy2']),
      approveBy: j['ApproveBy'] == null || j['ApproveBy'] == '' ? null : _asString(j['ApproveBy']),
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: _asInt(j['HourMeter']),
      // ⬇️ NEW
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),
    );
  }

  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoProduksi': noProduksi,
    'IdOperator': idOperator,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'NamaOperator': namaOperator,
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
    // ⬇️ NEW: send back as "HH:mm" strings (backend can parse to TIME)
    'HourStart': hourStart,
    'HourEnd': hourEnd,
  };

  String get tglProduksiTextShort {
    if (tglProduksi == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get tglProduksiTextFull {
    if (tglProduksi == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  // ⬇️ Optional helpers
  String get hourRangeText {
    if ((hourStart == null || hourStart!.isEmpty) &&
        (hourEnd == null || hourEnd!.isEmpty)) return '';
    return '${hourStart ?? '--:--'} - ${hourEnd ?? '--:--'}';
  }
}
