import 'so_v2_lokasi.dart';

class SoV2LokasiPage {
  final String stockOpnameNo;
  final String categoryCode;
  final String categoryName;
  final bool isComplete;
  final String blok;
  final List<SoV2Lokasi> data;
  final int totalRecords;

  SoV2LokasiPage({
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.categoryName,
    required this.isComplete,
    required this.blok,
    required this.data,
    required this.totalRecords,
  });

  factory SoV2LokasiPage.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List? ?? [])
        .map((e) => SoV2Lokasi.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return SoV2LokasiPage(
      stockOpnameNo: json['stockOpnameNo']?.toString() ?? '',
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      isComplete: json['isComplete'] as bool? ?? false,
      blok: json['blok']?.toString() ?? '',
      data: items,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
    );
  }
}
