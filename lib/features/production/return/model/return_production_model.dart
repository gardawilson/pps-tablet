// lib/features/shared/return_production/model/packing_production_model.dart

class ReturnProduction {
  final String noRetur;
  final String invoice;
  final DateTime tanggal;
  final int idPembeli;
  final String namaPembeli;
  final String noBJSortir;

  ReturnProduction({
    required this.noRetur,
    required this.invoice,
    required this.tanggal,
    required this.idPembeli,
    required this.namaPembeli,
    required this.noBJSortir,
  });

  factory ReturnProduction.fromJson(Map<String, dynamic> j) {
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
            // fallback if BE sends only 'YYYY-MM-DD'
            return DateTime.parse('${v}T00:00:00');
          } catch (_) {
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    return ReturnProduction(
      noRetur: (j['NoRetur'] ?? '') as String,
      invoice: (j['Invoice'] ?? '') as String,
      tanggal: _parseDate(j['Tanggal']),
      idPembeli: _toInt(j['IdPembeli']),
      namaPembeli: (j['NamaPembeli'] ?? '') as String,
      noBJSortir: (j['NoBJSortir'] ?? '') as String,
    );
  }
}
