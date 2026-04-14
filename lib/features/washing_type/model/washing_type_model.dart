class WashingType {
  final int idWashing;
  final String nama;
  final int? idUom;
  final int? idForm;
  final String? picPacking;
  final String? picContent;
  final String? itemCode;
  final bool enable;
  final bool? isReject;
  final bool? isDisableMinMax;

  const WashingType({
    required this.idWashing,
    required this.nama,
    this.idUom,
    this.idForm,
    this.picPacking,
    this.picContent,
    this.itemCode,
    required this.enable,
    this.isReject,
    this.isDisableMinMax,
  });

  static int _toInt(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static bool _toBool(dynamic v, {bool def = false}) {
    if (v == null) return def;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'y' || s == 'yes';
    }
    return def;
  }

  factory WashingType.fromJson(Map<String, dynamic> j) {
    final id = j['IdWashing'] ?? j['idWashing'];
    final nama = j['Nama'] ?? j['nama'] ?? '';

    return WashingType(
      idWashing: _toInt(id),
      nama: nama.toString(),
      idUom: j['IdUOM'] != null ? _toInt(j['IdUOM']) : null,
      idForm: j['IdForm'] != null ? _toInt(j['IdForm']) : null,
      picPacking: j['PicPacking']?.toString(),
      picContent: j['PicContent']?.toString(),
      itemCode: j['ItemCode']?.toString(),
      enable: _toBool(j['IsEnable'] ?? j['Enable'] ?? j['enable'], def: true),
      isReject: j['IsReject'] != null ? _toBool(j['IsReject']) : null,
      isDisableMinMax: j['IsDisableMinMax'] != null
          ? _toBool(j['IsDisableMinMax'])
          : null,
    );
  }

  Map<String, dynamic> toJson({bool serverCase = true}) {
    if (serverCase) {
      return {
        'IdWashing': idWashing,
        'Nama': nama,
        'IdUOM': idUom,
        'IdForm': idForm,
        'PicPacking': picPacking,
        'PicContent': picContent,
        'ItemCode': itemCode,
        'IsEnable': enable,
        'IsReject': isReject,
        'IsDisableMinMax': isDisableMinMax,
      };
    }

    return {
      'idWashing': idWashing,
      'nama': nama,
      'idUom': idUom,
      'idForm': idForm,
      'picPacking': picPacking,
      'picContent': picContent,
      'itemCode': itemCode,
      'enable': enable,
      'isReject': isReject,
      'isDisableMinMax': isDisableMinMax,
    };
  }

  WashingType copyWith({
    int? idWashing,
    String? nama,
    int? idUom,
    int? idForm,
    String? picPacking,
    String? picContent,
    String? itemCode,
    bool? enable,
    bool? isReject,
    bool? isDisableMinMax,
  }) {
    return WashingType(
      idWashing: idWashing ?? this.idWashing,
      nama: nama ?? this.nama,
      idUom: idUom ?? this.idUom,
      idForm: idForm ?? this.idForm,
      picPacking: picPacking ?? this.picPacking,
      picContent: picContent ?? this.picContent,
      itemCode: itemCode ?? this.itemCode,
      enable: enable ?? this.enable,
      isReject: isReject ?? this.isReject,
      isDisableMinMax: isDisableMinMax ?? this.isDisableMinMax,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WashingType && other.idWashing == idWashing;

  @override
  int get hashCode => idWashing.hashCode;

  @override
  String toString() =>
      'WashingType(id: $idWashing, nama: $nama, itemCode: $itemCode, enable: $enable)';
}
