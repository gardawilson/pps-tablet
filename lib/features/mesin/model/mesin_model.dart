class MstMesin {
  final int idMesin;
  final String namaMesin;
  final String bagian;
  final String? defaultOperator;
  final bool enable;
  final num? kapasitas;
  final int? idUom;
  final num? shotWeightPs;
  final num? klemLebar;
  final num? klemPanjang;
  final int? idBagianMesin;
  final num? target;

  MstMesin({
    required this.idMesin,
    required this.namaMesin,
    required this.bagian,
    this.defaultOperator,
    required this.enable,
    this.kapasitas,
    this.idUom,
    this.shotWeightPs,
    this.klemLebar,
    this.klemPanjang,
    this.idBagianMesin,
    this.target,
  });

  factory MstMesin.fromJson(Map<String, dynamic> j) {
    int? _toIntN(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    int _toInt(dynamic v) => _toIntN(v) ?? 0;

    num? _toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'y' || s == 'yes';
      }
      return false;
    }

    return MstMesin(
      idMesin: _toInt(j['IdMesin']),
      namaMesin: (j['NamaMesin'] ?? '') as String,
      bagian: (j['Bagian'] ?? '') as String,
      defaultOperator: j['DefaultOperator'] as String?,
      enable: _toBool(j['Enable']),
      kapasitas: _toNum(j['Kapasitas']),
      idUom: _toIntN(j['IdUOM']),
      shotWeightPs: _toNum(j['ShotWeightPS']),
      klemLebar: _toNum(j['KlemLebar']),
      klemPanjang: _toNum(j['KlemPanjang']),
      idBagianMesin: _toIntN(j['IdBagianMesin']),
      target: _toNum(j['Target']),
    );
  }
}
