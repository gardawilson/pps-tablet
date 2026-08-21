import 'package:intl/intl.dart';

class PenjualanHeader {
  final String noBJJual;
  final DateTime? tanggal;
  final int idPembeli;
  final String namaPembeli;
  final String? remark;
  final int totalLines;
  final int completedLines;
  final bool isComplete;
  final DateTime? dateComplete;

  const PenjualanHeader({
    required this.noBJJual,
    required this.tanggal,
    required this.idPembeli,
    required this.namaPembeli,
    this.remark,
    this.totalLines = 0,
    this.completedLines = 0,
    this.isComplete = false,
    this.dateComplete,
  });

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

  factory PenjualanHeader.fromJson(Map<String, dynamic> j) {
    return PenjualanHeader(
      noBJJual: _asString(j['NoBJJual']),
      tanggal: _asDateTime(j['Tanggal']),
      idPembeli: _asIntRequired(j['IdPembeli']),
      namaPembeli: _asString(j['NamaPembeli']),
      remark: (j['Remark'] == null || j['Remark'] == '')
          ? null
          : _asString(j['Remark']),
      totalLines: _asIntRequired(j['TotalLines']),
      completedLines: _asIntRequired(j['CompletedLines']),
      isComplete: _asBool(j['IsComplete']),
      dateComplete: _asDateTime(j['DateComplete']),
    );
  }

  String get tanggalText {
    if (tanggal == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }
}
