// lib/features/shared/return_production/model/return_production_model.dart
import 'package:intl/intl.dart';

class ReturnProduction {
  final String noRetur;

  /// backend: Invoice (nullable in DB)
  final String invoice;

  /// backend: Tanggal
  final DateTime? tanggal;

  /// backend: IdPembeli
  final int idPembeli;

  /// backend: NamaPembeli
  final String namaPembeli;

  /// backend: NoBJSortir (nullable)
  final String noBJSortir;

  // ✅ Tutup transaksi flags (optional from backend)
  final DateTime? lastClosedDate; // date only
  final bool isLocked;

  const ReturnProduction({
    required this.noRetur,
    required this.invoice,
    required this.tanggal,
    required this.idPembeli,
    required this.namaPembeli,
    required this.noBJSortir,
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

  factory ReturnProduction.fromJson(Map<String, dynamic> j) {
    return ReturnProduction(
      noRetur: _asString(j['NoRetur']),
      invoice: _asString(j['Invoice']),
      tanggal: _asDateTime(j['Tanggal']),
      idPembeli: _asIntRequired(j['IdPembeli']),
      namaPembeli: _asString(j['NamaPembeli']),
      noBJSortir: _asString(j['NoBJSortir']),
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
        'noRetur': noRetur,
        'invoice': invoice.isEmpty ? null : invoice,
        'tanggal': tanggal == null
            ? null
            : (asDateOnly
            ? DateFormat('yyyy-MM-dd').format(tanggal!)
            : tanggal!.toIso8601String()),
        'idPembeli': idPembeli,
        'noBJSortir': noBJSortir.isEmpty ? null : noBJSortir,
      };
    }

    return {
      'NoRetur': noRetur,
      'Invoice': invoice,
      'Tanggal': tanggal == null
          ? null
          : (asDateOnly
          ? DateFormat('yyyy-MM-dd').format(tanggal!)
          : tanggal!.toIso8601String()),
      'IdPembeli': idPembeli,
      'NamaPembeli': namaPembeli,
      'NoBJSortir': noBJSortir,
      'LastClosedDate': lastClosedDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(lastClosedDate!),
      'IsLocked': isLocked,
    };
  }

  // --- text helpers (consistent with sortir reject) ---
  String get tanggalTextShort {
    if (tanggal == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
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

  ReturnProduction copyWith({
    String? noRetur,
    String? invoice,
    DateTime? tanggal,
    int? idPembeli,
    String? namaPembeli,
    String? noBJSortir,
    DateTime? lastClosedDate,
    bool? isLocked,
  }) {
    return ReturnProduction(
      noRetur: noRetur ?? this.noRetur,
      invoice: invoice ?? this.invoice,
      tanggal: tanggal ?? this.tanggal,
      idPembeli: idPembeli ?? this.idPembeli,
      namaPembeli: namaPembeli ?? this.namaPembeli,
      noBJSortir: noBJSortir ?? this.noBJSortir,
      lastClosedDate: lastClosedDate ?? this.lastClosedDate,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
