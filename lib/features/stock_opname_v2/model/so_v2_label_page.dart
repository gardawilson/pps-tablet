import 'so_v2_label_group.dart';

class SoV2LabelPage {
  final String stockOpnameNo;
  final String categoryCode;
  final String? blok;
  final int? locationId;
  final bool isComplete;
  final List<SoV2LabelGroup> data;
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final double totalWeight;
  final int totalScanned;

  SoV2LabelPage({
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.blok,
    required this.locationId,
    required this.isComplete,
    required this.data,
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.totalWeight,
    required this.totalScanned,
  });

  factory SoV2LabelPage.fromJson(Map<String, dynamic> json) {
    final groups = (json['data'] as List? ?? [])
        .map(
          (e) => SoV2LabelGroup.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    return SoV2LabelPage(
      stockOpnameNo: json['stockOpnameNo']?.toString() ?? '',
      categoryCode: json['categoryCode']?.toString() ?? '',
      blok: json['blok']?.toString(),
      locationId: (json['locationId'] as num?)?.toInt(),
      isComplete: json['isComplete'] as bool? ?? false,
      data: groups,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      // Kategori berbasis pcs (mis. furniturewip) mengirim "totalPcs",
      // bukan "totalWeight".
      totalWeight:
          (json['totalWeight'] as num?)?.toDouble() ??
          (json['totalPcs'] as num?)?.toDouble() ??
          0,
      totalScanned: (json['totalScanned'] as num?)?.toInt() ?? 0,
    );
  }
}
