// lib/features/shared/inject_production/model/inject_production_model.dart
class InjectProduction {
  final String noProduksi;
  final int idOperator;
  final String namaOperator;       // backend belum join → keep empty string
  final int idMesin;
  final String namaMesin;
  final DateTime tglProduksi;
  final int jam;                   // NOTE: Inject uses "Jam" (not JamKerja)
  final int shift;
  final String? createBy;
  final String? checkBy1;
  final String? checkBy2;
  final String? approveBy;
  final int jmlhAnggota;
  final int hadir;
  final num? hourMeter;
  final int? idCetakan;
  final int? idWarna;
  final bool? enableOffset;
  final num? offsetCurrent;
  final num? offsetNext;
  final int? idFurnitureMaterial;
  final num? beratProdukHasilTimbang;

  InjectProduction({
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
    this.idCetakan,
    this.idWarna,
    this.enableOffset,
    this.offsetCurrent,
    this.offsetNext,
    this.idFurnitureMaterial,
    this.beratProdukHasilTimbang,
  });

  factory InjectProduction.fromJson(Map<String, dynamic> j) {
    T? _castNum<T extends num>(dynamic v) {
      if (v == null) return null;
      if (v is num) return v as T;
      if (v is String) return (num.tryParse(v) as T?);
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool? _toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'y' || s == 'yes';
      }
      return null;
    }

    return InjectProduction(
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
      idCetakan: (j['IdCetakan'] as num?)?.toInt(),
      idWarna: (j['IdWarna'] as num?)?.toInt(),
      enableOffset: _toBool(j['EnableOffset']),
      offsetCurrent: _castNum<num>(j['OffsetCurrent']),
      offsetNext: _castNum<num>(j['OffsetNext']),
      idFurnitureMaterial: (j['IdFurnitureMaterial'] as num?)?.toInt(),
      beratProdukHasilTimbang: _castNum<num>(j['BeratProdukHasilTimbang']),
    );
  }
}
