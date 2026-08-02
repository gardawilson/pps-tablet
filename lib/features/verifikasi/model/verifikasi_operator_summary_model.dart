// lib/features/verifikasi/model/verifikasi_operator_summary_model.dart
//
// GET /api/production/<jenis>/:noProduksi/verification-summary
//
// Dipakai untuk header dialog "Verifikasi Production Controller" & "Verifikasi
// Kadept" — bentuk `header` di response endpoint verification-summary sudah
// seragam lintas jenis produksi (washing, broker, dst: field SC/PC/DeptHead
// yang sama), jadi satu model & parser generik ini dipakai bersama oleh
// semua [VerifikasiAdapter] yang mendukungnya. Cross-check input/output
// TIDAK diambil dari sini — tetap pakai [VerifikasiAdapter.fetchCrossCheck]
// yang sudah ada supaya konsisten dengan dialog Stock Controller & tidak
// perlu re-parse bentuk inputs/outputs yang berbeda-beda per jenis.

String? _asStringOrNull(dynamic v) {
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

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

class VerifikasiOperatorEntry {
  final int idOperator;
  final String namaOperator;

  const VerifikasiOperatorEntry({
    required this.idOperator,
    required this.namaOperator,
  });

  factory VerifikasiOperatorEntry.fromJson(Map<String, dynamic> j) {
    return VerifikasiOperatorEntry(
      idOperator: _asInt(j['IdOperator']) ?? 0,
      namaOperator: _asStringOrNull(j['NamaOperator']) ?? '-',
    );
  }
}

/// Header generik verifikasi 3 tahap (Stock Controller → Production
/// Controller → Kadept) — sama untuk semua jenis produksi yang
/// men-support endpoint verification-summary.
class VerifikasiOperatorHeader {
  final String noProduksi;
  final String? namaMesin;
  final List<VerifikasiOperatorEntry> operators;
  final String? namaOperators;
  final String? outputJenisNama;
  final DateTime? tglProduksi;
  final int? jamKerja;
  final int? shift;
  final bool isComplete;

  final bool verified; // Stock Controller
  final DateTime? verifiedAt;
  final bool verifiedOperator; // Production Controller
  final DateTime? operatorVerifiedAt;
  final bool verifiedDepartment; // Kadept
  final DateTime? departmentVerifiedAt;

  final int? jmlhAnggota;
  final int? hadir;
  final num? hourMeter;

  /// Null untuk jenis produksi yang tidak punya konsep blower (mis. broker).
  final bool isBlower;

  final String? hourStart;
  final String? hourEnd;
  final int? idRegu;
  final String? namaRegu;

  const VerifikasiOperatorHeader({
    required this.noProduksi,
    this.namaMesin,
    this.operators = const [],
    this.namaOperators,
    this.outputJenisNama,
    this.tglProduksi,
    this.jamKerja,
    this.shift,
    this.isComplete = false,
    this.verified = false,
    this.verifiedAt,
    this.verifiedOperator = false,
    this.operatorVerifiedAt,
    this.verifiedDepartment = false,
    this.departmentVerifiedAt,
    this.jmlhAnggota,
    this.hadir,
    this.hourMeter,
    this.isBlower = false,
    this.hourStart,
    this.hourEnd,
    this.idRegu,
    this.namaRegu,
  });

  factory VerifikasiOperatorHeader.fromJson(Map<String, dynamic> j) {
    final rawOperators = (j['Operators'] as List?) ?? const [];
    final verifiedAt = _parseDate(j['SCVerifiedAt'] ?? j['VerifiedAt']);
    final operatorVerifiedAt =
        _parseDate(j['PCVerifiedAt'] ?? j['OperatorVerifiedAt']);
    final departmentVerifiedAt =
        _parseDate(j['DeptHeadVerifiedAt'] ?? j['DepartmentVerifiedAt']);

    return VerifikasiOperatorHeader(
      noProduksi: _asStringOrNull(j['NoProduksi']) ?? '-',
      namaMesin: _asStringOrNull(j['NamaMesin']),
      operators: rawOperators
          .map((e) => VerifikasiOperatorEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      namaOperators: _asStringOrNull(j['NamaOperators']),
      outputJenisNama: _asStringOrNull(j['OutputJenisNama']),
      tglProduksi: _parseDate(j['TglProduksi']),
      jamKerja: _asInt(j['JamKerja']),
      shift: _asInt(j['Shift']),
      isComplete: _asBool(j['IsComplete']),
      verified: j.containsKey('Verified')
          ? _asBool(j['Verified'])
          : verifiedAt != null,
      verifiedAt: verifiedAt,
      verifiedOperator: j.containsKey('VerifiedOperator')
          ? _asBool(j['VerifiedOperator'])
          : operatorVerifiedAt != null,
      operatorVerifiedAt: operatorVerifiedAt,
      verifiedDepartment: j.containsKey('VerifiedDepartment')
          ? _asBool(j['VerifiedDepartment'])
          : departmentVerifiedAt != null,
      departmentVerifiedAt: departmentVerifiedAt,
      jmlhAnggota: _asInt(j['JmlhAnggota']),
      hadir: _asInt(j['Hadir']),
      hourMeter: _asNum(j['HourMeter']),
      isBlower: _asBool(j['IsBlower']),
      hourStart: _asStringOrNull(j['HourStart']),
      hourEnd: _asStringOrNull(j['HourEnd']),
      idRegu: _asInt(j['IdRegu']),
      namaRegu: _asStringOrNull(j['NamaRegu']),
    );
  }
}
