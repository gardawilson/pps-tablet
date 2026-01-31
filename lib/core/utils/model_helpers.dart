// lib/features/production/shared/models/model_helpers.dart

/* ===================== PARSER HELPERS (PUBLIC - tanpa underscore) ===================== */

num? pickN(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
  }
  return null;
}

String? asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double? asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().toLowerCase().trim();
  if (s == '1' || s == 'true' || s == 't' || s == 'yes' || s == 'y') return true;
  if (s == '0' || s == 'false' || s == 'f' || s == 'no' || s == 'n') return false;
  return null;
}

/// Ambil string dari beberapa kandidat key
String? pickS(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = asString(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

int? pickI(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = asInt(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

double? pickD(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = asDouble(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

bool? pickB(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) {
      final v = asBool(j[k]);
      if (v != null) return v;
    }
  }
  return null;
}

DateTime? pickDT(Map<String, dynamic> j, List<String> keys) {
  dynamic v;
  for (final k in keys) {
    if (j.containsKey(k)) {
      v = j[k];
      break;
    }
  }
  if (v == null) return null;

  if (v is DateTime) return v;

  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final maybeNum = num.tryParse(s);
    if (maybeNum != null) {
      final n = maybeNum.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
          n >= 1000000000000 ? n : n * 1000, isUtc: true);
    }
    return null;
  }

  if (v is num) {
    final n = v.toInt();
    return DateTime.fromMillisecondsSinceEpoch(
        n >= 1000000000000 ? n : n * 1000, isUtc: true);
  }

  return null;
}