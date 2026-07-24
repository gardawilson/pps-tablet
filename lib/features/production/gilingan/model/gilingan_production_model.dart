import 'package:intl/intl.dart';

import '../../inject/model/inject_production_model.dart' show MachineStatus;

class GilinganProduction {
  final String noProduksi;
  final int idOperator;
  final int idMesin;
  final String namaMesin;
  final String namaOperator;
  final DateTime? tglProduksi;
  final int shift;
  final String createBy;
  final int? jmlhAnggota;
  final int? hadir;
  final int? hourMeter;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;

  // Hanya pakai ini untuk jam kerja
  final String? hourStart; // "HH:mm"
  final String? hourEnd;   // "HH:mm"

  final int? outputJenisId;
  final String? outputJenisNama;
  final int? idRegu;
  final String? namaRegu;

  // ✅ tutup transaksi flags
  final DateTime? lastClosedDate;
  final bool isLocked;

  // complete status
  final bool isComplete;
  final String? produksiStatus;

  // ✅ Verifikasi supervisor (terpisah dari isComplete/produksiStatus)
  final bool verified;
  final int? verifiedBy;
  final String? verifiedByUsername;
  final DateTime? verifiedAt;
  final String? verifyNote;

  const GilinganProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.namaOperator,
    required this.tglProduksi,
    required this.shift,
    required this.createBy,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    this.hourStart,
    this.hourEnd,
    this.outputJenisId,
    this.outputJenisNama,
    this.idRegu,
    this.namaRegu,
    this.lastClosedDate,
    this.isLocked = false,
    this.isComplete = false,
    this.produksiStatus,
    this.verified = false,
    this.verifiedBy,
    this.verifiedByUsername,
    this.verifiedAt,
    this.verifyNote,
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

  /// Normalisasi MSSQL TIME ke "HH:mm"
  static String? _asTimeHHmm(dynamic v) {
    if (v == null) return null;

    if (v is DateTime) {
      return DateFormat('HH:mm').format(v.toLocal());
    }

    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;

      final asDt = DateTime.tryParse(s);
      if (asDt != null) {
        // Use UTC to avoid timezone shift on epoch-date time-only values
        // e.g. "1970-01-01T16:00:00.000Z" must stay 16:00, not 23:00 (UTC+7)
        return DateFormat('HH:mm').format(asDt.toUtc());
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

  factory GilinganProduction.fromJson(Map<String, dynamic> j) {
    return GilinganProduction(
      noProduksi: _asString(j['NoProduksi']),
      idOperator: _asIntRequired(j['IdOperator']),
      idMesin: _asIntRequired(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),
      namaOperator: _asString(j['NamaOperators'] ?? j['NamaOperator']),
      tglProduksi: _asDateTime(j['Tanggal'] ?? j['TglProduksi']),
      shift: _asIntRequired(j['Shift']),
      createBy: _asString(j['CreateBy']),
      checkBy1: (j['CheckBy1'] == null || j['CheckBy1'] == '')
          ? null
          : _asString(j['CheckBy1']),
      checkBy2: (j['CheckBy2'] == null || j['CheckBy2'] == '')
          ? null
          : _asString(j['CheckBy2']),
      approveBy: (j['ApproveBy'] == null || j['ApproveBy'] == '')
          ? null
          : _asString(j['ApproveBy']),
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: _asInt(j['HourMeter']),
      hourStart: _asTimeHHmm(j['HourStart']),
      hourEnd: _asTimeHHmm(j['HourEnd']),
      outputJenisId: _asInt(j['OutputJenisId']),
      outputJenisNama: (j['OutputJenisNama'] == null || j['OutputJenisNama'] == '')
          ? null
          : _asString(j['OutputJenisNama']),
      idRegu: _asInt(j['IdRegu']),
      namaRegu: (j['NamaRegu'] == null || j['NamaRegu'] == '')
          ? null
          : _asString(j['NamaRegu']),
      lastClosedDate: _asDateTime(j['LastClosedDate']),
      isLocked: _asBool(j['IsLocked']),
      isComplete: _asBool(j['IsComplete'], fallback: false) ||
          j['status']?.toString() == 'complete',
      produksiStatus: j['status']?.toString() ??
          (_asBool(j['IsComplete'], fallback: false) ? 'complete' : 'pending'),
      verified: _asBool(j['Verified'], fallback: false),
      verifiedBy: _asInt(j['VerifiedBy']),
      verifiedByUsername: j['VerifiedByUsername'] as String?,
      verifiedAt: _asDateTime(j['VerifiedAt']),
      verifyNote: j['VerifiedNote'] as String?,
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

    // biasanya read-only, tidak perlu dikirim balik
    // 'LastClosedDate': lastClosedDate?.toIso8601String(),
    // 'IsLocked': isLocked,
  };

  String get tglProduksiTextShort {
    if (tglProduksi == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tglProduksi!.toLocal());
  }

  String get tglProduksiTextFull {
    if (tglProduksi == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID')
        .format(tglProduksi!.toLocal());
  }

  String get hourRangeText {
    if ((hourStart == null || hourStart!.isEmpty) &&
        (hourEnd == null || hourEnd!.isEmpty)) return '';
    return '${hourStart ?? '--:--'} - ${hourEnd ?? '--:--'}';
  }

  GilinganProduction copyWith({
    String? namaMesin,
    String? namaOperator,
    DateTime? tglProduksi,
    String? outputJenisNama,
    int? outputJenisId,
    String? namaRegu,
    int? idRegu,
    String? hourStart,
    String? hourEnd,
    bool? isComplete,
    String? produksiStatus,
  }) {
    return GilinganProduction(
      noProduksi: noProduksi,
      idOperator: idOperator,
      idMesin: idMesin,
      namaMesin: namaMesin ?? this.namaMesin,
      namaOperator: namaOperator ?? this.namaOperator,
      tglProduksi: tglProduksi ?? this.tglProduksi,
      shift: shift,
      createBy: createBy,
      jmlhAnggota: jmlhAnggota,
      hadir: hadir,
      hourMeter: hourMeter,
      checkBy1: checkBy1,
      checkBy2: checkBy2,
      approveBy: approveBy,
      hourStart: hourStart ?? this.hourStart,
      hourEnd: hourEnd ?? this.hourEnd,
      outputJenisId: outputJenisId ?? this.outputJenisId,
      outputJenisNama: outputJenisNama ?? this.outputJenisNama,
      idRegu: idRegu ?? this.idRegu,
      namaRegu: namaRegu ?? this.namaRegu,
      lastClosedDate: lastClosedDate,
      isLocked: isLocked,
      isComplete: isComplete ?? this.isComplete,
      produksiStatus: produksiStatus ?? this.produksiStatus,
      verified: verified,
      verifiedBy: verifiedBy,
      verifiedByUsername: verifiedByUsername,
      verifiedAt: verifiedAt,
      verifyNote: verifyNote,
    );
  }

  // Optional untuk UI
  String get lockInfoText {
    if (!isLocked) return '';
    if (lastClosedDate == null) return 'Locked';
    final d = DateFormat('dd MMM yyyy', 'id_ID').format(lastClosedDate!.toLocal());
    return 'Locked (<= $d)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GilinganMesinInfo — untuk panel kiri mesin screen
// ─────────────────────────────────────────────────────────────────────────────
class GilinganMesinInfo {
  final int idMesin;
  final String namaMesin;
  final String bagian;
  final String? noProduksi;
  final DateTime? tglProduksi;
  final int? idRegu;
  final String? namaRegu;
  final int? outputJenisId;
  final String? outputJenisNama;
  final List<int> idOperators;
  final String? operators;
  final int? shift;
  final String? hourStart;
  final String? hourEnd;
  final MachineStatus machineStatus;

  /// Ada produksi tercatat untuk mesin ini (aktif ataupun pending).
  bool get hasProduction => noProduksi != null;

  bool get isActive => machineStatus == MachineStatus.active;
  bool get isPending => machineStatus == MachineStatus.pending;

  const GilinganMesinInfo({
    required this.idMesin,
    required this.namaMesin,
    required this.bagian,
    this.noProduksi,
    this.tglProduksi,
    this.idRegu,
    this.namaRegu,
    this.outputJenisId,
    this.outputJenisNama,
    this.idOperators = const [],
    this.operators,
    this.shift,
    this.hourStart,
    this.hourEnd,
    this.machineStatus = MachineStatus.inactive,
  });

  factory GilinganMesinInfo.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) =>
        v == null ? null : v.toString().trim().isEmpty ? null : v.toString().trim();
    int? i(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    String? timeHHmm(dynamic v) {
      final raw = s(v);
      if (raw == null) return null;
      final parts = raw.split(':');
      if (parts.length < 2) return raw;
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    MachineStatus parseStatus(dynamic v) {
      switch (v?.toString()) {
        case 'current':
        case 'active':
        case 'aktif':
          return MachineStatus.active;
        case 'pending':
          return MachineStatus.pending;
        default:
          return MachineStatus.inactive;
      }
    }

    final List<int> ids = [];
    final raw = j['IdOperators'];
    if (raw is List) {
      for (final x in raw) {
        final n = i(x);
        if (n != null) ids.add(n);
      }
    } else {
      final n = i(raw);
      if (n != null) ids.add(n);
    }

    return GilinganMesinInfo(
      idMesin: i(j['IdMesin']) ?? 0,
      namaMesin: s(j['NamaMesin']) ?? '',
      bagian: s(j['Bagian']) ?? '',
      noProduksi: s(j['NoProduksi']),
      tglProduksi: j['TglProduksi'] == null
          ? null
          : DateTime.tryParse(j['TglProduksi'].toString()),
      idRegu: i(j['IdRegu']),
      namaRegu: s(j['NamaRegu']),
      outputJenisId: i(j['OutputJenisId']),
      outputJenisNama: s(j['OutputJenisNama']),
      idOperators: ids,
      operators: s(j['Operators']),
      shift: i(j['Shift']),
      hourStart: timeHHmm(j['HourStart']),
      hourEnd: timeHHmm(j['HourEnd']),
      machineStatus: parseStatus(j['status'] ?? j['machineStatus']),
    );
  }
}
