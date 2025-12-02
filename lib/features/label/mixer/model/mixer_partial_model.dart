class MixerPartialInfo {
  final double totalPartialWeight;
  final List<MixerPartialRow> rows;

  const MixerPartialInfo({
    required this.totalPartialWeight,
    required this.rows,
  });

  /// Parse directly from the API envelope:
  /// { success, message, totalRows, totalPartialWeight, data: [...], meta: {...} }
  factory MixerPartialInfo.fromEnvelope(Map<String, dynamic> body) {
    final rowsJson = (body['data'] as List?) ?? const [];
    return MixerPartialInfo(
      totalPartialWeight: (body['totalPartialWeight'] as num? ?? 0).toDouble(),
      rows: rowsJson
          .map((e) => MixerPartialRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MixerPartialRow {
  final String noMixerPartial;  // NoMixerPartial
  final String noMixer;         // NoMixer
  final int noSak;              // NoSak
  final double berat;           // Berat (partial weight)

  /// BROKER / INJECT / MIXER / null
  final String? sourceType;     // SourceType

  final String? noProduksi;     // NoProduksi
  final String? tglProduksi;    // already formatted by API
  final int? idMesin;           // IdMesin
  final String? namaMesin;      // NamaMesin
  final int? idOperator;        // IdOperator
  final String? jam;            // Jam
  final String? shift;          // Shift

  const MixerPartialRow({
    required this.noMixerPartial,
    required this.noMixer,
    required this.noSak,
    required this.berat,
    this.sourceType,
    this.noProduksi,
    this.tglProduksi,
    this.idMesin,
    this.namaMesin,
    this.idOperator,
    this.jam,
    this.shift,
  });

  // ---- helpers ----
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory MixerPartialRow.fromJson(Map<String, dynamic> j) {
    return MixerPartialRow(
      noMixerPartial: (j['NoMixerPartial'] ?? '').toString(),
      noMixer: (j['NoMixer'] ?? '').toString(),
      noSak: _toInt(j['NoSak']) ?? 0,
      berat: _toDouble(j['Berat']),
      sourceType: j['SourceType']?.toString(),
      noProduksi: j['NoProduksi']?.toString(),
      tglProduksi: j['TglProduksi']?.toString(),
      idMesin: _toInt(j['IdMesin']),
      namaMesin: j['NamaMesin']?.toString(),
      idOperator: _toInt(j['IdOperator']),
      jam: j['Jam']?.toString(),
      shift: j['Shift']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoMixerPartial': noMixerPartial,
    'NoMixer': noMixer,
    'NoSak': noSak,
    'Berat': berat,
    'SourceType': sourceType,
    'NoProduksi': noProduksi,
    'TglProduksi': tglProduksi,
    'IdMesin': idMesin,
    'NamaMesin': namaMesin,
    'IdOperator': idOperator,
    'Jam': jam,
    'Shift': shift,
  };
}
