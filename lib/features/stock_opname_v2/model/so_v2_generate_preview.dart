// lib/features/stock_opname_v2/model/so_v2_generate_preview.dart

class SoV2GeneratePreviewJenis {
  final int typeId;
  final String typeName;
  final int labelCount;
  final double totalWeight;

  const SoV2GeneratePreviewJenis({
    required this.typeId,
    required this.typeName,
    required this.labelCount,
    required this.totalWeight,
  });

  factory SoV2GeneratePreviewJenis.fromJson(Map<String, dynamic> json) {
    return SoV2GeneratePreviewJenis(
      typeId: (json['typeId'] as num?)?.toInt() ?? 0,
      typeName: json['typeName']?.toString() ?? '-',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Preview sebelum generate No. Stock Opname — GET
/// `/stock-opname-v2/transaksi/preview?categoryId=...`. Dipakai buat
/// dialog konfirmasi generate, breakdown per jenis biar supervisor tahu
/// persis apa yang bakal ke-generate sebelum benar-benar bikin SO baru.
class SoV2GeneratePreview {
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final DateTime? date;
  final bool hasDateFilter;
  final int labelCount;
  final double totalWeight;
  final List<SoV2GeneratePreviewJenis> perJenis;

  const SoV2GeneratePreview({
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    this.date,
    required this.hasDateFilter,
    required this.labelCount,
    required this.totalWeight,
    required this.perJenis,
  });

  factory SoV2GeneratePreview.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final jenisList = (json['perJenis'] ?? []) as List;

    return SoV2GeneratePreview(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      date: parseDate(json['date']),
      hasDateFilter: json['hasDateFilter'] == true,
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
      perJenis: jenisList
          .map((e) => SoV2GeneratePreviewJenis.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
