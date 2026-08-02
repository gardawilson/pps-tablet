// lib/features/production/washing/model/washing_verification_summary_model.dart
//
// GET /api/production/washing/:noProduksi/verification-summary
//
// Dipakai untuk dialog "Verifikasi Operator" — beda dari inputs/v2 &
// outputs/v2 (dipakai dialog "Verifikasi Kepala Stok") karena endpoint ini
// juga membawa info penugasan (operator, regu, kehadiran) yang jadi dasar
// verifikasi operator, di luar cross-check berat input/output.

import 'washing_inputs_v2_model.dart';

// ---------- Tolerant parsers ----------
// Field seperti VerifiedBy/OperatorVerifiedBy/DepartmentVerifiedBy bisa
// dikirim backend sebagai int (user id) atau string (username) tergantung
// endpoint — jangan cast langsung `as String?`/`as int?`, selalu lewat sini.
String? _asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
  }
  return fallback;
}

class WashingVerificationOperator {
  final int idOperator;
  final String namaOperator;

  const WashingVerificationOperator({
    required this.idOperator,
    required this.namaOperator,
  });

  factory WashingVerificationOperator.fromJson(Map<String, dynamic> j) {
    return WashingVerificationOperator(
      idOperator: _asInt(j['IdOperator']) ?? 0,
      namaOperator: _asString(j['NamaOperator']) ?? '-',
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

class WashingVerificationHeader {
  final String noProduksi;
  final int? idMesin;
  final String? namaMesin;
  final List<WashingVerificationOperator> operators;
  final String? namaOperators;
  final int? outputJenisId;
  final String? outputJenisNama;
  final DateTime? tglProduksi;
  final int? jamKerja;
  final int? shift;
  final bool isComplete;
  final bool verified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verifiedNote;
  final bool verifiedOperator;
  final String? operatorVerifiedBy;
  final DateTime? operatorVerifiedAt;
  final String? operatorVerifiedNote;
  final bool verifiedDepartment;
  final String? departmentVerifiedBy;
  final DateTime? departmentVerifiedAt;
  final String? departmentVerifiedNote;
  final int? jmlhAnggota;
  final int? hadir;
  final num? hourMeter;
  final bool isBlower;
  final String? hourStart;
  final String? hourEnd;
  final int? idRegu;
  final String? namaRegu;

  const WashingVerificationHeader({
    required this.noProduksi,
    this.idMesin,
    this.namaMesin,
    this.operators = const [],
    this.namaOperators,
    this.outputJenisId,
    this.outputJenisNama,
    this.tglProduksi,
    this.jamKerja,
    this.shift,
    this.isComplete = false,
    this.verified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.verifiedNote,
    this.verifiedOperator = false,
    this.operatorVerifiedBy,
    this.operatorVerifiedAt,
    this.operatorVerifiedNote,
    this.verifiedDepartment = false,
    this.departmentVerifiedBy,
    this.departmentVerifiedAt,
    this.departmentVerifiedNote,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.isBlower = false,
    this.hourStart,
    this.hourEnd,
    this.idRegu,
    this.namaRegu,
  });

  factory WashingVerificationHeader.fromJson(Map<String, dynamic> j) {
    final rawOperators = (j['Operators'] as List?) ?? const [];
    return WashingVerificationHeader(
      noProduksi: _asString(j['NoProduksi']) ?? '-',
      idMesin: _asInt(j['IdMesin']),
      namaMesin: _asString(j['NamaMesin']),
      operators: rawOperators
          .map((e) => WashingVerificationOperator.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      namaOperators: _asString(j['NamaOperators']),
      outputJenisId: _asInt(j['OutputJenisId']),
      outputJenisNama: _asString(j['OutputJenisNama']),
      tglProduksi: _parseDate(j['TglProduksi']),
      jamKerja: _asInt(j['JamKerja']),
      shift: _asInt(j['Shift']),
      isComplete: _asBool(j['IsComplete']),
      verified: _asBool(j['Verified']),
      verifiedBy: _asString(j['VerifiedBy']),
      verifiedAt: _parseDate(j['VerifiedAt']),
      verifiedNote: _asString(j['VerifiedNote']),
      verifiedOperator: _asBool(j['VerifiedOperator']),
      operatorVerifiedBy: _asString(j['OperatorVerifiedBy']),
      operatorVerifiedAt: _parseDate(j['OperatorVerifiedAt']),
      operatorVerifiedNote: _asString(j['OperatorVerifiedNote']),
      verifiedDepartment: _asBool(j['VerifiedDepartment']),
      departmentVerifiedBy: _asString(j['DepartmentVerifiedBy']),
      departmentVerifiedAt: _parseDate(j['DepartmentVerifiedAt']),
      departmentVerifiedNote: _asString(j['DepartmentVerifiedNote']),
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: _asNum(j['HourMeter']),
      isBlower: _asBool(j['IsBlower']),
      hourStart: _asString(j['HourStart']),
      hourEnd: _asString(j['HourEnd']),
      idRegu: _asInt(j['IdRegu']),
      namaRegu: _asString(j['NamaRegu']),
    );
  }
}

class WashingVerificationSummary {
  final WashingVerificationHeader header;
  final WashingInputsV2 inputs;
  final WashingOutputsV2 outputs;

  const WashingVerificationSummary({
    required this.header,
    required this.inputs,
    required this.outputs,
  });

  factory WashingVerificationSummary.fromJson(Map<String, dynamic> j) {
    return WashingVerificationSummary(
      header: WashingVerificationHeader.fromJson(
        Map<String, dynamic>.from(j['header'] as Map? ?? {}),
      ),
      inputs: WashingInputsV2.fromJson(
        Map<String, dynamic>.from(j['inputs'] as Map? ?? {}),
      ),
      outputs: WashingOutputsV2.fromJson(
        Map<String, dynamic>.from(j['outputs'] as Map? ?? {}),
      ),
    );
  }
}
