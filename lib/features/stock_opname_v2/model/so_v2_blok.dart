class SoV2Blok {
  final String blok;
  final int locationCount;
  final int labelCount;
  final int scannedCount;
  final double totalWeight;
  final int workingLocationCount;

  SoV2Blok({
    required this.blok,
    required this.locationCount,
    required this.labelCount,
    required this.scannedCount,
    required this.totalWeight,
    this.workingLocationCount = 0,
  });

  double get progress => labelCount > 0 ? scannedCount / labelCount : 0;

  SoV2Blok copyWith({
    int? scannedCount,
    double? totalWeight,
    int? workingLocationCount,
  }) {
    return SoV2Blok(
      blok: blok,
      locationCount: locationCount,
      labelCount: labelCount,
      scannedCount: scannedCount ?? this.scannedCount,
      totalWeight: totalWeight ?? this.totalWeight,
      workingLocationCount: workingLocationCount ?? this.workingLocationCount,
    );
  }

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
      workingLocationCount:
          (json['workingLocationCount'] as num?)?.toInt() ?? 0,
    );
  }
}
