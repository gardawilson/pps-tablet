// lib/features/shared/gilingan_production/model/packing_production_model.dart

class GilinganProduction {
  final String noProduksi;
  final int idOperator;
  final String namaOperator; // backend not joined yet → keep empty for now
  final int idMesin;
  final String namaMesin;
  final DateTime tanggal;    // from [GilinganProduksi_h].[Tanggal]
  final int jam;
  final int shift;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int jmlhAnggota;
  final int hadir;
  final num? hourMeter;

  GilinganProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.namaOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.tanggal,
    required this.jam,
    required this.shift,
    this.createBy,
    this.checkBy1,
    this.checkBy2,
    this.approveBy,
    required this.jmlhAnggota,
    required this.hadir,
    this.hourMeter,
  });

  factory GilinganProduction.fromJson(Map<String, dynamic> j) {
    T? _castNum<T extends num>(dynamic v) {
      if (v == null) return null;
      if (v is num) return v as T;
      if (v is String) return num.tryParse(v) as T?;
      return null;
    }

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
          return DateTime.parse(v);
        } catch (_) {
          // fallback if BE ever sends just 'YYYY-MM-DD'
          try {
            return DateTime.parse('${v}T00:00:00');
          } catch (_) {
            return DateTime.now();
          }
        }
      }
      return DateTime.now();
    }

    return GilinganProduction(
      noProduksi: (j['NoProduksi'] ?? '') as String,
      idOperator: _toInt(j['IdOperator']),
      namaOperator: (j['NamaOperator'] ?? '') as String, // if later you join operator name
      idMesin: _toInt(j['IdMesin']),
      namaMesin: (j['NamaMesin'] ?? '') as String,
      tanggal: _parseDate(j['Tanggal']),       // 👈 from GilinganProduksi_h.Tanggal
      jam: _toInt(j['Jam']),
      shift: _toInt(j['Shift']),
      createBy: j['CreateBy'] as String?,
      checkBy1: j['CheckBy1'] as String?,
      checkBy2: j['CheckBy2'] as String?,
      approveBy: j['ApproveBy'] as String?,
      jmlhAnggota: _toInt(j['JmlhAnggota']),
      hadir: _toInt(j['Hadir']),
      hourMeter: _castNum<num>(j['HourMeter']),
    );
  }
}
