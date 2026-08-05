import 'so_v2_blok.dart';

/// Wrapper response `GET .../blok` — sekarang membawa status selesai di
/// level stock opname (bukan cuma per-blok/per-lokasi seperti sebelumnya).
class SoV2BlokPage {
  final String stockOpnameNo;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final bool isComplete;
  final DateTime? completedAt;
  final List<SoV2Blok> data;
  final int totalRecords;

  SoV2BlokPage({
    required this.stockOpnameNo,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.isComplete,
    this.completedAt,
    required this.data,
    required this.totalRecords,
  });

  factory SoV2BlokPage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final items = (json['data'] as List? ?? [])
        .map((e) => SoV2Blok.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return SoV2BlokPage(
      stockOpnameNo: json['stockOpnameNo']?.toString() ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      isComplete: json['isComplete'] == true,
      completedAt: parseDate(json['completedAt']),
      data: items,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
    );
  }
}
