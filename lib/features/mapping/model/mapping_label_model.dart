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
    // Format tanggal ISO → "dd/mm/yyyy"
    String dateStr = (json['DateCreate'] ?? '').toString();
    try {
      final dt = DateTime.parse(dateStr);
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {}

    return MappingLabelItem(
      labelCode: (json['LabelCode'] ?? '').toString(),
      dateCreate: dateStr,
      namaJenis: (json['NamaJenis'] ?? '').toString(),
      kategori: (json['Kategori'] ?? '').toString(),
      uom: (json['NamaUOM'] ?? json['Uom'] ?? '').toString(),
      blok: (json['Blok'] ?? '').toString(),
      idLokasi: (json['IdLokasi'] as num?)?.toInt() ?? 0,
      qty: (json['Qty'] as num?)?.toInt() ?? 0,
      berat: (json['Berat'] as num?)?.toDouble(),
    );
  }
}

class MappingLabelHistoryItem {
  final DateTime? eventTime;
  final String actorUsername;
  final String beforeBlok;
  final int? beforeIdLokasi;
  final String afterBlok;
  final int? afterIdLokasi;

  MappingLabelHistoryItem({
    required this.eventTime,
    required this.actorUsername,
    required this.beforeBlok,
    required this.beforeIdLokasi,
    required this.afterBlok,
    required this.afterIdLokasi,
  });

  factory MappingLabelHistoryItem.fromJson(Map<String, dynamic> json) {
    return MappingLabelHistoryItem(
      eventTime: DateTime.tryParse((json['eventTime'] ?? '').toString()),
      actorUsername: (json['actorUsername'] ?? '').toString(),
      beforeBlok: (json['beforeBlok'] ?? '').toString(),
      beforeIdLokasi: (json['beforeIdLokasi'] as num?)?.toInt(),
      afterBlok: (json['afterBlok'] ?? '').toString(),
      afterIdLokasi: (json['afterIdLokasi'] as num?)?.toInt(),
    );
  }
}

class MappingLabelHistoryResult {
  final String labelCode;
  final List<MappingLabelHistoryItem> history;

  MappingLabelHistoryResult({required this.labelCode, required this.history});
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
