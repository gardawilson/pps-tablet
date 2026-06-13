class MappingLabelItem {
  final String labelCode;
  final String dateCreate;
  final String namaJenis;
  final String kategori;
  final String uom;
  final String blok;
  final int idLokasi;
  final int qty;
  final double? berat;

  MappingLabelItem({
    required this.labelCode,
    required this.dateCreate,
    required this.namaJenis,
    required this.kategori,
    required this.uom,
    required this.blok,
    required this.idLokasi,
    required this.qty,
    required this.berat,
  });

  factory MappingLabelItem.fromJson(Map<String, dynamic> json) {
    return MappingLabelItem(
      labelCode: (json['LabelCode'] ?? '').toString(),
      dateCreate: (json['DateCreate'] ?? '').toString(),
      namaJenis: (json['NamaJenis'] ?? '').toString(),
      kategori: (json['Kategori'] ?? '').toString(),
      uom: (json['Uom'] ?? '').toString(),
      blok: (json['Blok'] ?? '').toString(),
      idLokasi: (json['IdLokasi'] as num?)?.toInt() ?? 0,
      qty: (json['Qty'] as num?)?.toInt() ?? 0,
      berat: (json['Berat'] as num?)?.toDouble(),
    );
  }
}

class MappingLabelResult {
  final List<MappingLabelItem> data;
  final int totalData;
  final int totalQty;
  final double totalBerat;

  MappingLabelResult({
    required this.data,
    required this.totalData,
    required this.totalQty,
    required this.totalBerat,
  });
}
