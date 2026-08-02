// lib/features/shared/washing_production/model/washing_production_model.dart
import 'package:intl/intl.dart';

class WashingProduction {
  final String noProduksi;

  /// Multi-operator support (new API)
  final List<int> idOperators;

  /// Comma-separated operator names e.g. "ABDUL, BUDI"
  final String namaOperators;

  final int idMesin;
  final String namaMesin;
  final DateTime? tglProduksi;
  final int jamKerja;
  final int shift;
  final bool isBlower;
  final String createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int? jmlhAnggota;
  final int? hadir;
  final int? hourMeter;
  final String? hourStart; // "HH:mm"
  final String? hourEnd;   // "HH:mm"

  // Output jenis
  final int? outputJenisId;
  final String? outputJenisNama;

  // ✅ Tutup transaksi flags
  final bool isLocked;
  final DateTime? lastClosedDate;

  // ✅ Regu
  final int? idRegu;
  final String? namaRegu;

  // ✅ Complete status
  final bool isComplete;
  final String? produksiStatus;

  // ✅ Verifikasi kepala stok (terpisah dari isComplete/produksiStatus)
  final bool verified;
  final int? verifiedBy;
  final String? verifiedByUsername;
  final DateTime? verifiedAt;
  final String? verifyNote;

  // ✅ Verifikasi operator — terpisah dari verifikasi kepala stok di atas
  final bool verifiedOperator;
  final int? operatorVerifiedBy;
  final String? operatorVerifiedByUsername;
  final DateTime? operatorVerifiedAt;
  final String? operatorVerifyNote;

  // ✅ Verifikasi department (final) — tahap ketiga, setelah kepala stok
  // & operator tuntas
  final bool verifiedDepartment;
  final int? departmentVerifiedBy;
  final String? departmentVerifiedByUsername;
  final DateTime? departmentVerifiedAt;
  final String? departmentVerifyNote;

  // ✅ Rendemen — hanya terisi kalau di-request dengan ?includeRendemen=true
  final double? totalInputBerat;
  final double? totalOutputBerat;
  final double? rendemen;

  const WashingProduction({
    required this.noProduksi,
    required this.idOperators,
    required this.namaOperators,
    required this.idMesin,
    required this.namaMesin,
    required this.tglProduksi,
    required this.jamKerja,
    required this.shift,
    this.isBlower = false,
    required this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.hourStart,
    this.hourEnd,
    this.outputJenisId,
    this.outputJenisNama,
    required this.isLocked,
    this.lastClosedDate,
    this.idRegu,
    this.namaRegu,
    this.isComplete = false,
    this.produksiStatus,
    this.verified = false,
    this.verifiedBy,
    this.verifiedByUsername,
    this.verifiedAt,
    this.verifyNote,
    this.verifiedOperator = false,
    this.operatorVerifiedBy,
    this.operatorVerifiedByUsername,
    this.operatorVerifiedAt,
    this.operatorVerifyNote,
    this.verifiedDepartment = false,
    this.departmentVerifiedBy,
    this.departmentVerifiedByUsername,
    this.departmentVerifiedAt,
    this.departmentVerifyNote,
    this.totalInputBerat,
    this.totalOutputBerat,
    this.rendemen,
  });

  // ── Backward-compat getters ──────────────────────────────────────────────
  int get idOperator => idOperators.isNotEmpty ? idOperators.first : 0;
  String get namaOperator => namaOperators;

  // ---------- Tolerant parsers ----------
  static String _asString(dynamic v) => v?.toString() ?? '';

  /// Beberapa field (mis. VerifiedByUsername) kadang dikirim backend
  /// sebagai int (user id) alih-alih string — jangan cast langsung
  /// `as String?`, selalu lewat sini supaya tidak crash type-cast.
  static String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

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
    final hm = _asDouble(j['HourMeter']);

    // Support both array (new) and single int (legacy)
    List<int> parseIdOperators(dynamic v) {
      if (v is List) return v.map((e) => _asIntRequired(e)).where((e) => e != 0).toList();
      final single = _asInt(v);
      return single != null ? [single] : [];
    }

    final idOperators = parseIdOperators(j['IdOperators'] ?? j['IdOperator']);
    final namaOperators = _asString(j['NamaOperators'] ?? j['NamaOperator']);

    final scVerifiedAt = _asDateTime(j['SCVerifiedAt'] ?? j['VerifiedAt']);
    final pcVerifiedAt = _asDateTime(j['PCVerifiedAt'] ?? j['OperatorVerifiedAt']);
    final deptHeadVerifiedAt =
        _asDateTime(j['DeptHeadVerifiedAt'] ?? j['DepartmentVerifiedAt']);

    return WashingProduction(
      noProduksi: _asString(j['NoProduksi']),
      idOperators: idOperators,
      namaOperators: namaOperators,
      idMesin: _asIntRequired(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),
      tglProduksi: _asDateTime(j['TglProduksi']),
      jamKerja: _asIntRequired(j['JamKerja']),
      shift: _asIntRequired(j['Shift']),
      isBlower: _asBool(j['IsBlower'] ?? j['isBlower'], fallback: false),
      createBy: _asString(j['CreateBy']),
      checkBy1: (j['CheckBy1'] == null || _asString(j['CheckBy1']).trim().isEmpty)
          ? null : _asString(j['CheckBy1']),
      checkBy2: (j['CheckBy2'] == null || _asString(j['CheckBy2']).trim().isEmpty)
          ? null : _asString(j['CheckBy2']),
      approveBy: (j['ApproveBy'] == null || _asString(j['ApproveBy']).trim().isEmpty)
          ? null : _asString(j['ApproveBy']),
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: hm?.round(),
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),
      outputJenisId: _asInt(j['OutputJenisId']),
      outputJenisNama: j['OutputJenisNama'] == null
          ? null : _asString(j['OutputJenisNama']).trim().isEmpty
          ? null : _asString(j['OutputJenisNama']),
      isLocked: _asBool(j['IsLocked'], fallback: false),
      lastClosedDate: _asDateTime(j['LastClosedDate']),
      idRegu: _asInt(j['IdRegu']),
      namaRegu: _asStringOrNull(j['NamaRegu']),
      isComplete: _asBool(j['IsComplete'], fallback: false) ||
          j['status']?.toString() == 'complete',
      produksiStatus: j['status']?.toString() ??
          (_asBool(j['IsComplete'], fallback: false) ? 'complete' : 'pending'),
      // Nama field backend berubah jadi prefix SC/PC/DeptHead — tetap
      // fallback ke nama lama (Verified*/Operator*/Department*) supaya
      // kompatibel kalau ada endpoint lain yang belum ikut berubah. Selain
      // itu, sebagian respons (mis. ?verified=1) tidak lagi mengirim flag
      // boolean Verified/VerifiedOperator/VerifiedDepartment sama sekali —
      // kalau key-nya absen, derive dari *VerifiedAt (non-null = sudah
      // diverifikasi) alih-alih fallback ke false begitu saja.
      verified: j.containsKey('Verified')
          ? _asBool(j['Verified'], fallback: false)
          : scVerifiedAt != null,
      verifiedBy: _asInt(j['SCVerifiedBy'] ?? j['VerifiedBy']),
      verifiedByUsername:
          _asStringOrNull(j['SCVerifiedByUsername'] ?? j['VerifiedByUsername']),
      verifiedAt: scVerifiedAt,
      verifyNote: _asStringOrNull(j['SCVerifiedNote'] ?? j['VerifiedNote']),
      verifiedOperator: j.containsKey('VerifiedOperator')
          ? _asBool(j['VerifiedOperator'], fallback: false)
          : pcVerifiedAt != null,
      operatorVerifiedBy: _asInt(j['PCVerifiedBy'] ?? j['OperatorVerifiedBy']),
      operatorVerifiedByUsername: _asStringOrNull(
          j['PCVerifiedByUsername'] ?? j['OperatorVerifiedByUsername']),
      operatorVerifiedAt: pcVerifiedAt,
      operatorVerifyNote:
          _asStringOrNull(j['PCVerifiedNote'] ?? j['OperatorVerifiedNote']),
      verifiedDepartment: j.containsKey('VerifiedDepartment')
          ? _asBool(j['VerifiedDepartment'], fallback: false)
          : deptHeadVerifiedAt != null,
      departmentVerifiedBy:
          _asInt(j['DeptHeadVerifiedBy'] ?? j['DepartmentVerifiedBy']),
      departmentVerifiedByUsername: _asStringOrNull(
          j['DeptHeadVerifiedByUsername'] ?? j['DepartmentVerifiedByUsername']),
      departmentVerifiedAt: deptHeadVerifiedAt,
      departmentVerifyNote: _asStringOrNull(
          j['DeptHeadVerifiedNote'] ?? j['DepartmentVerifiedNote']),
      totalInputBerat: _asDouble(j['TotalInputBerat']),
      totalOutputBerat: _asDouble(j['TotalOutputBerat']),
      rendemen: _asDouble(j['Rendemen']),
    );
  }

  Map<String, dynamic> toJson({bool asDateOnly = true}) => {
    'NoProduksi': noProduksi,
    'IdOperators': idOperators,
    'NamaOperators': namaOperators,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'TglProduksi': tglProduksi == null
        ? null
        : (asDateOnly
        ? DateFormat('yyyy-MM-dd').format(tglProduksi!)
        : tglProduksi!.toIso8601String()),
    'JamKerja': jamKerja,
    'Shift': shift,
    'IsBlower': isBlower,
    'CreateBy': createBy,
    'CheckBy1': checkBy1,
    'CheckBy2': checkBy2,
    'ApproveBy': approveBy,
    'JmlhAnggota': jmlhAnggota,
    'Hadir': hadir,
    'HourMeter': hourMeter,
    'HourStart': hourStart,
    'HourEnd': hourEnd,
    'IdRegu': idRegu,

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

// ─────────────────────────────────────────────────────────────────────────────
// WashingMesinInfo — hasil dari GET /api/mst-mesin/washing
// Satu baris = satu mesin, dengan info produksi hari ini (jika ada).
// ─────────────────────────────────────────────────────────────────────────────
class WashingMesinInfo {
  final int idMesin;
  final String namaMesin;
  final String? bagian;
  final int? target;

  // produksi hari ini (null = mesin belum aktif)
  final String? noProduksi;
  final DateTime? tglProduksi;
  final int? outputJenisId;
  final String? outputJenisNama;
  final String? outputJenisItemCode;
  final int? idOperator;
  final String? namaOperator;
  final String? namaRegu;
  final int? shift;
  final String? hourStart; // “HH:mm”
  final String? hourEnd;   // “HH:mm”
  final bool? isBlower;

  bool get isActive => noProduksi != null && noProduksi!.isNotEmpty;

  const WashingMesinInfo({
    required this.idMesin,
    required this.namaMesin,
    this.bagian,
    this.target,
    this.noProduksi,
    this.tglProduksi,
    this.outputJenisId,
    this.outputJenisNama,
    this.outputJenisItemCode,
    this.idOperator,
    this.namaOperator,
    this.namaRegu,
    this.shift,
    this.hourStart,
    this.hourEnd,
    this.isBlower,
  });

  static String? _s(dynamic v) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v.trim());
    return null;
  }

  static bool? _b(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return null;
  }

  /// Normalisasi TIME server ke “HH:mm”
  static String? _time(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return DateFormat('HH:mm').format(v.toUtc());
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final dt = DateTime.tryParse(s);
      if (dt != null) return DateFormat('HH:mm').format(dt.toUtc());
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
      if (m != null) {
        return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)!}';
      }
    }
    return null;
  }

  factory WashingMesinInfo.fromJson(Map<String, dynamic> j) {
    return WashingMesinInfo(
      idMesin: _i(j['IdMesin']) ?? 0,
      namaMesin: _s(j['NamaMesin']) ?? '',
      bagian: _s(j['Bagian']),
      target: _i(j['Target']),
      noProduksi: _s(j['NoProduksi']),
      tglProduksi: _dt(j['TglProduksi']),
      outputJenisId: _i(j['OutputJenisId']),
      outputJenisNama: _s(j['OutputJenisNama']),
      outputJenisItemCode: _s(j['OutputJenisItemCode']),
      idOperator: _i(j['IdOperator']),
      namaOperator: _s(j['NamaOperator']),
      namaRegu: _s(j['NamaRegu']),
      shift: _i(j['Shift']),
      hourStart: _time(j['HourStart']),
      hourEnd: _time(j['HourEnd']),
      isBlower: _b(j['IsBlower']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WashingActiveShift — info shift aktif dari endpoint mst-mesin/washing
// ─────────────────────────────────────────────────────────────────────────────
class WashingActiveShift {
  final int shift;
  final String hourStart; // “HH:mm:ss” or “HH:mm”
  final String hourEnd;

  const WashingActiveShift({
    required this.shift,
    required this.hourStart,
    required this.hourEnd,
  });

  /// Ambil hanya “HH:mm” dari string jam
  static String _trim5(String v) =>
      v.length >= 5 ? v.substring(0, 5) : v;

  factory WashingActiveShift.fromJson(Map<String, dynamic> j) {
    return WashingActiveShift(
      shift: (j['shift'] as num?)?.toInt() ?? 1,
      hourStart: _trim5((j['hourStart'] ?? '').toString()),
      hourEnd: _trim5((j['hourEnd'] ?? '').toString()),
    );
  }
}
