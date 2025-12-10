// lib/features/shared/sortir_reject_production/model/sortir_reject_production_model.dart

class SortirRejectProduction {
  final String noBJSortir;
  final DateTime tanggal;
  final int idUsername;
  final String username; // optional, kalau BE kirim NamaUser / Username

  SortirRejectProduction({
    required this.noBJSortir,
    required this.tanggal,
    required this.idUsername,
    required this.username,
  });

  factory SortirRejectProduction.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) {
        try {
          // support full ISO string
          return DateTime.parse(v);
        } catch (_) {
          try {
            // fallback kalau BE kirim 'YYYY-MM-DD' saja
            return DateTime.parse('${v}T00:00:00');
          } catch (_) {
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    String _toString(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    return SortirRejectProduction(
      noBJSortir: (j['NoBJSortir'] ?? '') as String,
      tanggal: _parseDate(j['TglBJSortir']),
      idUsername: _toInt(j['IdUsername']),
      // fleksibel: bisa 'Username' atau 'NamaUser' dari BE
      username: _toString(j['Username'] ?? j['NamaUser']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoBJSortir': noBJSortir,
      'TglBJSortir': tanggal.toIso8601String(),
      'IdUsername': idUsername,
      if (username.isNotEmpty) 'Username': username,
    };
  }
}
