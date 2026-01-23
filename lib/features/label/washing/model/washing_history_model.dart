// lib/features/label/washing/model/washing_history_model.dart
class WashingHistorySession {
  // timing
  final String startTime;
  final String endTime;

  // actor/session
  final String actor;
  final String? requestId; // bisa null
  final String sessionKey; // COALESCE(RequestId, 'AUDIT-<AuditId>')
  final String noWashing;

  // summary
  final String sessionAction;  // CREATE | UPDATE | DELETE
  final String sessionSummary;

  // =========================
  // ✅ ENRICH BEFORE (OLD)
  // =========================
  final int? oldIdJenisPlastik;
  final String? oldNamaJenisPlastik;

  final int? oldIdWarehouse;
  final String? oldNamaWarehouse;

  final String? oldBlok;
  final int? oldIdLokasi;

  final String? oldStatusText; // PASS | HOLD | ''
  final double? oldDensity;
  final double? oldMoisture;

  final String? oldNoProduksi;
  final String? oldNamaMesin;

  final String? oldNoBongkarSusun;

  // =========================
  // ✅ ENRICH AFTER (NEW)
  // =========================
  final int? newIdJenisPlastik;
  final String? newNamaJenisPlastik;

  final int? newIdWarehouse;
  final String? newNamaWarehouse;

  final String? newBlok;
  final int? newIdLokasi;

  final String? newStatusText; // PASS | HOLD | ''
  final double? newDensity;
  final double? newMoisture;

  final String? newNoProduksi;
  final String? newNamaMesin;

  final String? newNoBongkarSusun;

  // =========================
  // raw JSON-as-string (tetap)
  // =========================
  final String? headerInserted;
  final String? headerOld;
  final String? headerNew;
  final String? headerDeleted;

  final String? detailsOldJson;
  final String? detailsNewJson;

  final String? bsoOldJson;
  final String? bsoNewJson;

  final String? wpoOldJson;
  final String? wpoNewJson;

  const WashingHistorySession({
    required this.startTime,
    required this.endTime,
    required this.actor,
    required this.requestId,
    required this.sessionKey,
    required this.noWashing,
    required this.sessionAction,
    required this.sessionSummary,

    this.oldIdJenisPlastik,
    this.oldNamaJenisPlastik,
    this.oldIdWarehouse,
    this.oldNamaWarehouse,
    this.oldBlok,
    this.oldIdLokasi,
    this.oldStatusText,
    this.oldDensity,
    this.oldMoisture,
    this.oldNoProduksi,
    this.oldNamaMesin,
    this.oldNoBongkarSusun,

    this.newIdJenisPlastik,
    this.newNamaJenisPlastik,
    this.newIdWarehouse,
    this.newNamaWarehouse,
    this.newBlok,
    this.newIdLokasi,
    this.newStatusText,
    this.newDensity,
    this.newMoisture,
    this.newNoProduksi,
    this.newNamaMesin,
    this.newNoBongkarSusun,

    this.headerInserted,
    this.headerOld,
    this.headerNew,
    this.headerDeleted,
    this.detailsOldJson,
    this.detailsNewJson,
    this.bsoOldJson,
    this.bsoNewJson,
    this.wpoOldJson,
    this.wpoNewJson,
  });

  // helpers
  static String _s(dynamic v) => (v ?? '').toString();

  static String? _sN(dynamic v) {
    if (v == null) return null;
    final str = v.toString();
    return str.isEmpty ? null : str;
  }

  static int? _iN(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _dN(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory WashingHistorySession.fromJson(Map<String, dynamic> json) {
    return WashingHistorySession(
      startTime: _s(json['StartTime']),
      endTime: _s(json['EndTime']),
      actor: _s(json['Actor']),
      requestId: _sN(json['RequestId']),
      sessionKey: _s(json['SessionKey']),
      noWashing: _s(json['NoWashing']),
      sessionAction: _s(json['SessionAction']),
      sessionSummary: _s(json['SessionSummary']),

      // OLD
      oldIdJenisPlastik: _iN(json['OldIdJenisPlastik']),
      oldNamaJenisPlastik: _sN(json['OldNamaJenisPlastik']),
      oldIdWarehouse: _iN(json['OldIdWarehouse']),
      oldNamaWarehouse: _sN(json['OldNamaWarehouse']),
      oldBlok: _sN(json['OldBlok']),
      oldIdLokasi: _iN(json['OldIdLokasi']),
      oldStatusText: _sN(json['OldStatusText']),
      oldDensity: _dN(json['OldDensity']),
      oldMoisture: _dN(json['OldMoisture']),
      oldNoProduksi: _sN(json['OldNoProduksi']),
      oldNamaMesin: _sN(json['OldNamaMesin']),
      oldNoBongkarSusun: _sN(json['OldNoBongkarSusun']),

      // NEW
      newIdJenisPlastik: _iN(json['NewIdJenisPlastik']),
      newNamaJenisPlastik: _sN(json['NewNamaJenisPlastik']),
      newIdWarehouse: _iN(json['NewIdWarehouse']),
      newNamaWarehouse: _sN(json['NewNamaWarehouse']),
      newBlok: _sN(json['NewBlok']),
      newIdLokasi: _iN(json['NewIdLokasi']),
      newStatusText: _sN(json['NewStatusText']),
      newDensity: _dN(json['NewDensity']),
      newMoisture: _dN(json['NewMoisture']),
      newNoProduksi: _sN(json['NewNoProduksi']),
      newNamaMesin: _sN(json['NewNamaMesin']),
      newNoBongkarSusun: _sN(json['NewNoBongkarSusun']),

      // raw json strings
      headerInserted: _sN(json['HeaderInserted']),
      headerOld: _sN(json['HeaderOld']),
      headerNew: _sN(json['HeaderNew']),
      headerDeleted: _sN(json['HeaderDeleted']),

      detailsOldJson: _sN(json['DetailsOldJson']),
      detailsNewJson: _sN(json['DetailsNewJson']),

      bsoOldJson: _sN(json['BsoOldJson']),
      bsoNewJson: _sN(json['BsoNewJson']),

      wpoOldJson: _sN(json['WpoOldJson']),
      wpoNewJson: _sN(json['WpoNewJson']),
    );
  }

  // optional convenience: ambil "after/current" untuk display ringkas
  String? get currentNamaJenisPlastik => (newNamaJenisPlastik ?? oldNamaJenisPlastik);
  String? get currentNamaWarehouse => (newNamaWarehouse ?? oldNamaWarehouse);
  String? get currentStatusText => (newStatusText ?? oldStatusText);
  String? get currentNoProduksi => (newNoProduksi ?? oldNoProduksi);
  String? get currentNoBongkarSusun => (newNoBongkarSusun ?? oldNoBongkarSusun);
}
