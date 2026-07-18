class SoV2Blok {
  final String blok;
  final int locationCount;
  final int labelCount;
  final int scannedCount;
  final double totalWeight;

  SoV2Blok({
    required this.blok,
    required this.locationCount,
    required this.labelCount,
    required this.scannedCount,
    required this.totalWeight,
  });

  double get progress => labelCount > 0 ? scannedCount / labelCount : 0;

  factory SoV2Blok.fromJson(Map<String, dynamic> json) {
    return SoV2Blok(
      blok: json['blok']?.toString() ?? '',
      locationCount: (json['locationCount'] as num?)?.toInt() ?? 0,
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      // Kategori berbasis pcs (mis. furniturewip) mengirim "totalPcs",
      // bukan "totalWeight".
      totalWeight:
          (json['totalWeight'] as num?)?.toDouble() ??
          (json['totalPcs'] as num?)?.toDouble() ??
          0,
    );
  }
}
