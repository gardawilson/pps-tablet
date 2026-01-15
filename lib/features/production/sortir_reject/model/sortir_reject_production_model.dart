// lib/features/shared/sortir_reject_production/model/sortir_reject_production_model.dart
import 'package:intl/intl.dart';

class SortirRejectProduction {
  final String noBJSortir;

  /// backend: TglBJSortir
  final DateTime? tanggal;

  final int idUsername;

  /// backend: Username (atau NamaUser)
  final String username;

  /// backend: IdWarehouse (opsional, tapi sekarang BE sudah SELECT)
  final int? idWarehouse;

  // ✅ Tutup transaksi flags (optional from backend)
  final DateTime? lastClosedDate; // date only
  final bool isLocked;

  const SortirRejectProduction({
    required this.noBJSortir,
    required this.tanggal,
    required this.idUsername,
    required this.username,
    this.idWarehouse,
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

  factory SortirRejectProduction.fromJson(Map<String, dynamic> j) {
    return SortirRejectProduction(
      noBJSortir: _asString(j['NoBJSortir']),
      tanggal: _asDateTime(j['TglBJSortir']),
      idUsername: _asIntRequired(j['IdUsername']),
      username: _asString(j['Username'] ?? j['NamaUser']),
      idWarehouse: _asInt(j['IdWarehouse']),

      // ✅ optional lock flags if backend sends
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
        'noBJSortir': noBJSortir,
        'tglBJSortir': tanggal == null
            ? null
            : (asDateOnly
            ? DateFormat('yyyy-MM-dd').format(tanggal!)
            : tanggal!.toIso8601String()),
        'idUsername': idUsername,
        'idWarehouse': idWarehouse,
      };
    }

    return {
      'NoBJSortir': noBJSortir,
      'TglBJSortir': tanggal == null
          ? null
          : (asDateOnly
          ? DateFormat('yyyy-MM-dd').format(tanggal!)
          : tanggal!.toIso8601String()),
      'IdUsername': idUsername,
      'Username': username,
      'IdWarehouse': idWarehouse,
      'LastClosedDate': lastClosedDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(lastClosedDate!),
      'IsLocked': isLocked,
    };
  }

  // --- text helpers (biar konsisten dengan packing/spanner) ---
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

  SortirRejectProduction copyWith({
    String? noBJSortir,
    DateTime? tanggal,
    int? idUsername,
    String? username,
    int? idWarehouse,
    DateTime? lastClosedDate,
    bool? isLocked,
  }) {
    return SortirRejectProduction(
      noBJSortir: noBJSortir ?? this.noBJSortir,
      tanggal: tanggal ?? this.tanggal,
      idUsername: idUsername ?? this.idUsername,
      username: username ?? this.username,
      idWarehouse: idWarehouse ?? this.idWarehouse,
      lastClosedDate: lastClosedDate ?? this.lastClosedDate,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
