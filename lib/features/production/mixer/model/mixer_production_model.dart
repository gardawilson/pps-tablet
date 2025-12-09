// lib/features/shared/mixer_production/model/packing_production_model.dart

class MixerProduction {
  final String noProduksi;
  final int idOperator;
  final String namaOperator; // backend belum join → keep empty string for now
  final int idMesin;
  final String namaMesin;
  final DateTime tglProduksi;
  final int jam; // Mixer uses "Jam" (HHmm / jam kerja)
  final int shift;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int jmlhAnggota;
  final int hadir;
  final num? hourMeter;

  MixerProduction({
    required this.noProduksi,
    required this.idOperator,
    required this.namaOperator,
    required this.idMesin,
    required this.namaMesin,
    required this.tglProduksi,
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

  factory MixerProduction.fromJson(Map<String, dynamic> j) {
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

    return MixerProduction(
      noProduksi: (j['NoProduksi'] ?? '') as String,
      idOperator: _toInt(j['IdOperator']),
      namaOperator: (j['NamaOperator'] ?? '') as String, // not provided by BE now
      idMesin: _toInt(j['IdMesin']),
      namaMesin: (j['NamaMesin'] ?? '') as String,
      tglProduksi: DateTime.parse(j['TglProduksi'] as String),
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
