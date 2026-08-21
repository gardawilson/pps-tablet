// lib/features/production/penerimaan_bahan_baku/model/tim_penerimaan_bahan_baku_model.dart
//
// Mirror response dari GET /api/penerimaan-bahan-baku/tim-status — analog
// `WashingMesinInfo` (GET /api/mst-mesin/washing): satu baris = satu tim
// (dbo.MstTimPenerimaanBB), digabung dengan info NoPenerimaan yang dibuat
// HARI INI (jika ada). Tim tanpa transaksi hari ini dianggap "belum aktif".
class TimPenerimaanInfo {
  final int idTim;
  final String namaTim;
  final bool aktif;

  // transaksi penerimaan hari ini (null = tim belum aktif hari ini)
  final String? noPenerimaan;
  final DateTime? tglPenerimaan;
  final int? shift;
  final String? hourStart; // "HH:mm"
  final String? hourEnd; // "HH:mm"
  final String? namaOperators;

  bool get isActive => noPenerimaan != null && noPenerimaan!.isNotEmpty;

  const TimPenerimaanInfo({
    required this.idTim,
    required this.namaTim,
    required this.aktif,
    this.noPenerimaan,
    this.tglPenerimaan,
    this.shift,
    this.hourStart,
    this.hourEnd,
    this.namaOperators,
  });

  static String? _s(dynamic v) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v.trim());
    return null;
  }

  static String? _time(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
      if (m != null) return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)!}';
    }
    return null;
  }

  factory TimPenerimaanInfo.fromJson(Map<String, dynamic> j) {
    return TimPenerimaanInfo(
      idTim: _i(j['IdTim']),
      namaTim: _s(j['NamaTim']) ?? '',
      aktif: _b(j['Aktif']),
      noPenerimaan: _s(j['NoPenerimaan']),
      tglPenerimaan: _dt(j['TglPenerimaan']),
      shift: j['Shift'] != null ? _i(j['Shift']) : null,
      hourStart: _time(j['HourStart']),
      hourEnd: _time(j['HourEnd']),
      namaOperators: _s(j['NamaOperators']),
    );
  }
}
