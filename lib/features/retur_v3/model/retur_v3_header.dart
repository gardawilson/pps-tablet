import 'package:intl/intl.dart';

/// Header transaksi Retur v3 — parsing toleran terhadap key PascalCase
/// maupun camelCase karena bentuk pasti response backend belum final saat
/// file ini dibuat (lihat AGENTS.md kontrak `/api/retur-v3`).
class ReturV3Header {
  final String noRetur;
  final DateTime? tanggal;
  final int? idPembeli;
  final String? namaPembeli;
  final String? keterangan;

  /// 'PENDING' | 'DIGANTI' | 'TIDAK_DIGANTI'
  final String statusRetur;
  final bool isComplete;
  final String? decisionBy;
  final DateTime? decisionAt;
  final DateTime? dateCreate;

  /// Ringkasan progress turnover (hanya relevan saat statusRetur == DIGANTI):
  /// total pcs target dari semua item vs total pcs yang sudah dipenuhi lewat
  /// scan label. Dikirim backend sebagai agregat di endpoint list supaya
  /// tidak perlu fetch detail satu-satu.
  final int turnoverTargetPcs;
  final int turnoverScannedPcs;

  const ReturV3Header({
    required this.noRetur,
    this.tanggal,
    this.idPembeli,
    this.namaPembeli,
    this.keterangan,
    this.statusRetur = 'PENDING',
    this.isComplete = false,
    this.decisionBy,
    this.decisionAt,
    this.dateCreate,
    this.turnoverTargetPcs = 0,
    this.turnoverScannedPcs = 0,
  });

  bool get isPending => statusRetur.toUpperCase() == 'PENDING';
  bool get isDiganti => statusRetur.toUpperCase() == 'DIGANTI';
  bool get isTidakDiganti => statusRetur.toUpperCase() == 'TIDAK_DIGANTI';
  bool get hasDecision => !isPending;
  bool get isTurnoverFulfilled =>
      turnoverTargetPcs > 0 && turnoverScannedPcs >= turnoverTargetPcs;

  static String _s(dynamic v) => v?.toString() ?? '';
  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int? _iOpt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool _bool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return false;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory ReturV3Header.fromJson(Map<String, dynamic> j) {
    return ReturV3Header(
      noRetur: _s(_pick(j, ['noRetur', 'NoRetur'])),
      tanggal: _dt(_pick(j, ['tanggal', 'Tanggal'])),
      idPembeli: _iOpt(_pick(j, ['idPembeli', 'IdPembeli'])),
      namaPembeli: _pick(j, ['namaPembeli', 'NamaPembeli'])?.toString(),
      keterangan: _pick(j, ['keterangan', 'Keterangan'])?.toString(),
      statusRetur:
          _s(_pick(j, ['statusRetur', 'StatusRetur', 'status', 'Status']))
              .isEmpty
          ? 'PENDING'
          : _s(
              _pick(j, ['statusRetur', 'StatusRetur', 'status', 'Status']),
            ).toUpperCase(),
      isComplete: _bool(_pick(j, ['isComplete', 'IsComplete'])),
      decisionBy: _pick(j, ['decisionBy', 'DecisionBy'])?.toString(),
      decisionAt: _dt(_pick(j, ['decisionAt', 'DecisionAt'])),
      dateCreate: _dt(_pick(j, ['dateCreate', 'DateCreate'])),
      turnoverTargetPcs: _i(
        _pick(j, ['turnoverTargetPcs', 'TurnoverTargetPcs']),
      ),
      turnoverScannedPcs: _i(
        _pick(j, ['turnoverScannedPcs', 'TurnoverScannedPcs']),
      ),
    );
  }

  String get tanggalText {
    if (tanggal == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }

  ReturV3Header copyWith({
    String? statusRetur,
    bool? isComplete,
    String? keterangan,
    DateTime? tanggal,
    int? idPembeli,
    String? namaPembeli,
  }) {
    return ReturV3Header(
      noRetur: noRetur,
      tanggal: tanggal ?? this.tanggal,
      idPembeli: idPembeli ?? this.idPembeli,
      namaPembeli: namaPembeli ?? this.namaPembeli,
      keterangan: keterangan ?? this.keterangan,
      statusRetur: statusRetur ?? this.statusRetur,
      isComplete: isComplete ?? this.isComplete,
      decisionBy: decisionBy,
      decisionAt: decisionAt,
      dateCreate: dateCreate,
      turnoverTargetPcs: turnoverTargetPcs,
      turnoverScannedPcs: turnoverScannedPcs,
    );
  }
}
