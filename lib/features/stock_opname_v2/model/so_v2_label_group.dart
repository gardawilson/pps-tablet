import 'so_v2_label_row.dart';

/// Satu jenis label dalam satu lokasi (mis. "PP BONGGOL HITAM LEMARI"),
/// beserta baris-baris label snapshot di dalamnya.
class SoV2LabelGroup {
  final int? typeId;
  final String typeName;
  final int labelCount;
  final double totalWeight;
  final List<SoV2LabelRow> labels;

  SoV2LabelGroup({
    required this.typeId,
    required this.typeName,
    required this.labelCount,
    required this.totalWeight,
    required this.labels,
  });

  factory SoV2LabelGroup.fromJson(Map<String, dynamic> json) {
    final labels = (json['labels'] as List? ?? [])
        .map((e) => SoV2LabelRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return SoV2LabelGroup(
      typeId: (json['typeId'] as num?)?.toInt(),
      typeName: json['typeName']?.toString() ?? '',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      // Kategori berbasis pcs (mis. furniturewip) mengirim "totalPcs",
      // bukan "totalWeight".
      totalWeight:
          (json['totalWeight'] as num?)?.toDouble() ??
          (json['totalPcs'] as num?)?.toDouble() ??
          0,
      labels: labels,
    );
  }

  int get scannedCount => labels.where((l) => l.isScanned).length;
}
