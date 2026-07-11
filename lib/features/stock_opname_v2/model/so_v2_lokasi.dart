class SoV2Lokasi {
  final int locationId;
  final String description;
  final int labelCount;
  final int scannedCount;
  final double totalWeight;

  SoV2Lokasi({
    required this.locationId,
    required this.description,
    required this.labelCount,
    required this.scannedCount,
    required this.totalWeight,
  });

  double get progress => labelCount > 0 ? scannedCount / labelCount : 0;

  factory SoV2Lokasi.fromJson(Map<String, dynamic> json) {
    return SoV2Lokasi(
      locationId: (json['locationId'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}
