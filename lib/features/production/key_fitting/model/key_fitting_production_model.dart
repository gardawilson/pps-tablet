// lib/features/shared/key_fitting_production/model/packing_production_model.dart
import 'package:intl/intl.dart';

class KeyFittingProduction {
  final String noProduksi;
  final int idMesin;
  final int idOperator;

  final String namaMesin;
  final String namaOperator;

  final DateTime? tglProduksi;
  final int shift;

  /// Backend field "JamKerja"
  final int? jamKerja;

  final String createBy;

  final int? hourMeter;

  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;

  /// Jam kerja dalam format "HH:mm"
  final String? hourStart;
  final String? hourEnd;

  // ✅ Tutup transaksi flags (kalau backend kirim)
  final DateTime? lastClosedDate; // date only
  final bool isLocked;

  const KeyFittingProduction({
    required this.noProduksi,
    required this.idMesin,
    required this.idOperator,
    required this.namaMesin,
    required this.namaOperator,
    required this.tglProduksi,
    required this.shift,
    required this.createBy,
    this.jamKerja,
    this.hourMeter,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.hourStart,
    this.hourEnd,
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
    if (v is num) return v.toInt();
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
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  /// Normalisasi MSSQL TIME ke "HH:mm"
  static String? _asTimeHHmm(dynamic v) {
    if (v == null) return null;

    // TIME kadang dimapping ke DateTime (1900-01-01 + time)
    if (v is DateTime) {
      return DateFormat('HH:mm').format(v.toLocal());
    }

    // String: "HH:mm[:ss[.fff]]" atau "1900-01-01T07:30:00"
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

  factory KeyFittingProduction.fromJson(Map<String, dynamic> j) {
    return KeyFittingProduction(
      noProduksi: _asString(j['NoProduksi']),
      idMesin: _asIntRequired(j['IdMesin']),
      idOperator: _asIntRequired(j['IdOperator']),
      namaMesin: _asString(j['NamaMesin']),
      namaOperator: _asString(j['NamaOperator']),

      // backend kamu list bisa pakai 'Tanggal' (PasangKunci_h)
      // tapi biar seragam di model: simpan ke tglProduksi
      tglProduksi: _asDateTime(j['Tanggal'] ?? j['TglProduksi']),
      shift: _asIntRequired(j['Shift']),
      createBy: _asString(j['CreateBy']),
      checkBy1: j['CheckBy1'] == null || j['CheckBy1'] == ''
          ? null
          : _asString(j['CheckBy1']),
      checkBy2: j['CheckBy2'] == null || j['CheckBy2'] == ''
          ? null
          : _asString(j['CheckBy2']),
      approveBy: j['ApproveBy'] == null || j['ApproveBy'] == ''
          ? null
          : _asString(j['ApproveBy']),

      jamKerja: _asInt(j['JamKerja']),
      hourMeter: _asInt(j['HourMeter']),
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),

      // ✅ optional lock flags jika backend kirim
      lastClosedDate: _asDateTime(j['LastClosedDate']),
      isLocked: _asBool(j['IsLocked']),
    );
  }

  /// Default: output "format list/detail" (PascalCase).
  /// Untuk create/update endpoint (keys kecil):
  Map<String, dynamic> toJson({
    bool asDateOnly = true,
    bool forWritePayload = false,
  }) {
    if (forWritePayload) {
      return {
        'noProduksi': noProduksi,
        'idMesin': idMesin,
        'idOperator': idOperator,
        'tglProduksi': tglProduksi == null
            ? null
            : (asDateOnly
            ? DateFormat('yyyy-MM-dd').format(tglProduksi!)
            : tglProduksi!.toIso8601String()),
        'shift': shift,
        'jamKerja': jamKerja,
        'checkBy1': checkBy1,
        'checkBy2': checkBy2,
        'approveBy': approveBy,
        'hourMeter': hourMeter,
        'hourStart': hourStart,
        'hourEnd': hourEnd,
      };
    }

    return {
      'NoProduksi': noProduksi,
      'IdMesin': idMesin,
      'IdOperator': idOperator,
      'NamaMesin': namaMesin,
      'NamaOperator': namaOperator,
      'Tanggal': tglProduksi == null
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
      'HourMeter': hourMeter,
      'HourStart': hourStart,
      'HourEnd': hourEnd,
    };
  }

  // --- text helpers (ikut hotstamp) ---
  String get tglProduksiTextShort {
    if (tglProduksi == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get tglProduksiTextFull {
    if (tglProduksi == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get hourRangeText {
    if ((hourStart == null || hourStart!.isEmpty) &&
        (hourEnd == null || hourEnd!.isEmpty)) {
      return '';
    }
    return '${hourStart ?? '--:--'} - ${hourEnd ?? '--:--'}';
  }

  String get lockInfoText {
    if (!isLocked) return '';
    if (lastClosedDate == null) return 'Locked';
    final d = DateFormat('dd MMM yyyy', 'id_ID').format(lastClosedDate!.toLocal());
    return 'Locked (<= $d)';
  }

  bool get isEditable => !isLocked;

  String get lockStatusMessage {
    if (!isLocked) return 'Dapat diedit';
    if (lastClosedDate != null) {
      final d = DateFormat('dd/MM/yyyy').format(lastClosedDate!.toLocal());
      return 'Terkunci (Transaksi ditutup s/d $d)';
    }
    return 'Terkunci';
  }

  KeyFittingProduction copyWith({
    String? noProduksi,
    int? idMesin,
    int? idOperator,
    String? namaMesin,
    String? namaOperator,
    DateTime? tglProduksi,
    int? shift,
    String? createBy,
    int? jamKerja,
    int? hourMeter,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    String? hourStart,
    String? hourEnd,
    DateTime? lastClosedDate,
    bool? isLocked,
  }) {
    return KeyFittingProduction(
      noProduksi: noProduksi ?? this.noProduksi,
      idMesin: idMesin ?? this.idMesin,
      idOperator: idOperator ?? this.idOperator,
      namaMesin: namaMesin ?? this.namaMesin,
      namaOperator: namaOperator ?? this.namaOperator,
      tglProduksi: tglProduksi ?? this.tglProduksi,
      shift: shift ?? this.shift,
      createBy: createBy ?? this.createBy,
      jamKerja: jamKerja ?? this.jamKerja,
      hourMeter: hourMeter ?? this.hourMeter,
      checkBy1: checkBy1 ?? this.checkBy1,
      checkBy2: checkBy2 ?? this.checkBy2,
      approveBy: approveBy ?? this.approveBy,
      hourStart: hourStart ?? this.hourStart,
      hourEnd: hourEnd ?? this.hourEnd,
      lastClosedDate: lastClosedDate ?? this.lastClosedDate,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
