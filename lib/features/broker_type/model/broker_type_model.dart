class BrokerType {
  final int idBroker;
  final String nama;
  final int? idUom;
  final int? idForm;
  final String? picPacking;
  final String? picContent;
  final String? itemCode;
  final bool enable;
  final bool? isReject;
  final bool? isDisableMinMax;

  const BrokerType({
    required this.idBroker,
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

  factory BrokerType.fromJson(Map<String, dynamic> j) {
    final id = j['IdBroker'] ?? j['idBroker'];
    final nama = j['Nama'] ?? j['nama'] ?? '';

    return BrokerType(
      idBroker: _toInt(id),
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
        'IdBroker': idBroker,
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
      'idBroker': idBroker,
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

  BrokerType copyWith({
    int? idBroker,
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
    return BrokerType(
      idBroker: idBroker ?? this.idBroker,
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
      other is BrokerType && other.idBroker == idBroker;

  @override
  int get hashCode => idBroker.hashCode;

  @override
  String toString() =>
      'BrokerType(id: $idBroker, nama: $nama, itemCode: $itemCode, enable: $enable)';
}
