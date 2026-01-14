// lib/features/shared/bj_jual/model/bj_jual_model.dart
import 'package:intl/intl.dart';

class BJJual {
  final String noBJJual;
  final DateTime? tanggal;

  final int idPembeli;
  final String namaPembeli;

  final String? remark;

  /// optional: kalau suatu saat backend kirim tutup-transaksi flags
  final DateTime? lastClosedDate; // date only
  final bool isLocked;

  const BJJual({
    required this.noBJJual,
    required this.tanggal,
    required this.idPembeli,
    required this.namaPembeli,
    this.remark,
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

  factory BJJual.fromJson(Map<String, dynamic> j) {
    return BJJual(
      noBJJual: _asString(j['NoBJJual']),
      tanggal: _asDateTime(j['Tanggal']),
      idPembeli: _asIntRequired(j['IdPembeli']),
      namaPembeli: _asString(j['NamaPembeli']),
      remark: (j['Remark'] == null || j['Remark'] == '') ? null : _asString(j['Remark']),
      // optional lock flags (kalau backend mengirim)
      lastClosedDate: _asDateTime(j['LastClosedDate']),
      isLocked: _asBool(j['IsLocked']),
    );
  }

  /// Default output: list/detail (PascalCase).
  /// For create/update payload: camelCase keys like backend expects.
  Map<String, dynamic> toJson({
    bool asDateOnly = true,
    bool forWritePayload = false,
  }) {
    if (forWritePayload) {
      return {
        'noBJJual': noBJJual,
        'tanggal': tanggal == null
            ? null
            : (asDateOnly
            ? DateFormat('yyyy-MM-dd').format(tanggal!)
            : tanggal!.toIso8601String()),
        'idPembeli': idPembeli,
        'remark': remark,
      };
    }

    return {
      'NoBJJual': noBJJual,
      'Tanggal': tanggal == null
          ? null
          : (asDateOnly
          ? DateFormat('yyyy-MM-dd').format(tanggal!)
          : tanggal!.toIso8601String()),
      'IdPembeli': idPembeli,
      'NamaPembeli': namaPembeli,
      'Remark': remark,
      'LastClosedDate': lastClosedDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(lastClosedDate!),
      'IsLocked': isLocked,
    };
  }

  // --- text helpers ---
  String get tanggalTextShort {
    if (tanggal == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }

  String get tanggalTextFull {
    if (tanggal == null) return '';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }

  bool get isEditable => !isLocked;

  String get lockInfoText {
    if (!isLocked) return '';
    if (lastClosedDate == null) return 'Locked';
    final d = DateFormat('dd MMM yyyy', 'id_ID').format(lastClosedDate!.toLocal());
    return 'Locked (<= $d)';
  }


  String get lockStatusMessage {
    if (!isLocked) return 'Dapat diedit';
    if (lastClosedDate != null) {
      final d = DateFormat('dd/MM/yyyy').format(lastClosedDate!.toLocal());
      return 'Terkunci (Transaksi ditutup s/d $d)';
    }
    return 'Terkunci';
  }

  String get lockStatusMessageShort {
    if (!isLocked) return '';
    if (lastClosedDate != null) {
      final d = DateFormat('dd/MM/yyyy').format(lastClosedDate!.toLocal());
      return 'Terkunci s/d $d';
    }
    return 'Terkunci';
  }


  BJJual copyWith({
    String? noBJJual,
    DateTime? tanggal,
    int? idPembeli,
    String? namaPembeli,
    String? remark,
    DateTime? lastClosedDate,
    bool? isLocked,
  }) {
    return BJJual(
      noBJJual: noBJJual ?? this.noBJJual,
      tanggal: tanggal ?? this.tanggal,
      idPembeli: idPembeli ?? this.idPembeli,
      namaPembeli: namaPembeli ?? this.namaPembeli,
      remark: remark ?? this.remark,
      lastClosedDate: lastClosedDate ?? this.lastClosedDate,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
