class BrokerPartialInfo {
  final double totalPartialWeight;
  final List<BrokerPartialRow> rows;

  const BrokerPartialInfo({
    required this.totalPartialWeight,
    required this.rows,
  });

  factory BrokerPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    // backend shape: { success, message, totalRows, totalPartialWeight, data: [...], meta: {...} }
    final rowsJson = (body['data'] as List?) ?? const [];
    return BrokerPartialInfo(
      totalPartialWeight: (body['totalPartialWeight'] as num? ?? 0).toDouble(),
      rows: rowsJson.map((e) => BrokerPartialRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class BrokerPartialRow {
  final String noBrokerPartial;
  final String noBroker;
  final int noSak;
  final double berat;
  final String? noProduksi;
  final String? tglProduksi; // already formatted by API
  final int? idMesin;
  final String? namaMesin;
  final int? idOperator;
  final String? jam;
  final String? shift;

  const BrokerPartialRow({
    required this.noBrokerPartial,
    required this.noBroker,
    required this.noSak,
    required this.berat,
    this.noProduksi,
    this.tglProduksi,
    this.idMesin,
    this.namaMesin,
    this.idOperator,
    this.jam,
    this.shift,
  });

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory BrokerPartialRow.fromJson(Map<String, dynamic> j) {
    return BrokerPartialRow(
      noBrokerPartial: (j['NoBrokerPartial'] ?? '').toString(),
      noBroker: (j['NoBroker'] ?? '').toString(),
      noSak: _toInt(j['NoSak']) ?? 0,
      berat: _toDouble(j['Berat']),
      noProduksi: j['NoProduksi']?.toString(),
      tglProduksi: j['TglProduksi']?.toString(),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: j['NamaMesin']?.toString(),
      idOperator: _toInt(j['IdOperator']),
      jam: j['Jam']?.toString(),
      shift: j['Shift']?.toString(),
    );
  }
}
