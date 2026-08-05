// lib/features/stock_opname_v2/model/so_v2_complete_summary.dart

/// Total lintas jenis/blok untuk satu stock opname — dipakai juga sebagai
/// baris per-jenis (`perJenis`) & per-blok (`perBlok`).
class SoV2CompleteSummaryTotal {
  final int labelCount;
  final int scannedCount;
  final int unscannedCount;
  final double totalWeight;

  const SoV2CompleteSummaryTotal({
    required this.labelCount,
    required this.scannedCount,
    required this.unscannedCount,
    required this.totalWeight,
  });

  factory SoV2CompleteSummaryTotal.fromJson(Map<String, dynamic> json) {
    return SoV2CompleteSummaryTotal(
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      unscannedCount: (json['unscannedCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SoV2CompleteSummaryJenis {
  final int typeId;
  final String typeName;
  final int labelCount;
  final int scannedCount;
  final int unscannedCount;
  final double totalWeight;

  const SoV2CompleteSummaryJenis({
    required this.typeId,
    required this.typeName,
    required this.labelCount,
    required this.scannedCount,
    required this.unscannedCount,
    required this.totalWeight,
  });

  factory SoV2CompleteSummaryJenis.fromJson(Map<String, dynamic> json) {
    return SoV2CompleteSummaryJenis(
      typeId: (json['typeId'] as num?)?.toInt() ?? 0,
      typeName: json['typeName']?.toString() ?? '-',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      unscannedCount: (json['unscannedCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SoV2CompleteSummaryBlok {
  final String blok;
  final int locationCount;
  final int labelCount;
  final int scannedCount;
  final int unscannedCount;
  final double totalWeight;

  const SoV2CompleteSummaryBlok({
    required this.blok,
    required this.locationCount,
    required this.labelCount,
    required this.scannedCount,
    required this.unscannedCount,
    required this.totalWeight,
  });

  factory SoV2CompleteSummaryBlok.fromJson(Map<String, dynamic> json) {
    return SoV2CompleteSummaryBlok(
      blok: json['blok']?.toString() ?? '-',
      locationCount: (json['locationCount'] as num?)?.toInt() ?? 0,
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
      unscannedCount: (json['unscannedCount'] as num?)?.toInt() ?? 0,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Ringkasan sebelum "Tandai Selesai" — GET
/// `/stock-opname-v2/transaksi/:stockOpnameNo/complete-summary`. Dipakai
/// buat konfirmasi supervisor: berapa label belum ke-scan, breakdown per
/// jenis & blok, dan berapa user yang aksesnya bakal ke-revoke otomatis
/// begitu SO ditandai selesai.
class SoV2CompleteSummary {
  final String stockOpnameNo;
  final DateTime? date;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final bool isComplete;
  final DateTime? completedAt;
  final SoV2CompleteSummaryTotal total;
  final List<SoV2CompleteSummaryJenis> perJenis;
  final List<SoV2CompleteSummaryBlok> perBlok;
  final int assignedUsersCount;

  const SoV2CompleteSummary({
    required this.stockOpnameNo,
    this.date,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.isComplete,
    this.completedAt,
    required this.total,
    required this.perJenis,
    required this.perBlok,
    required this.assignedUsersCount,
  });

  factory SoV2CompleteSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final totalJson = json['total'] as Map<String, dynamic>? ?? const {};
    final perJenisList = (json['perJenis'] ?? []) as List;
    final perBlokList = (json['perBlok'] ?? []) as List;

    return SoV2CompleteSummary(
      stockOpnameNo: json['stockOpnameNo']?.toString() ?? '',
      date: parseDate(json['date']),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      isComplete: json['isComplete'] == true,
      completedAt: parseDate(json['completedAt']),
      total: SoV2CompleteSummaryTotal.fromJson(totalJson),
      perJenis: perJenisList
          .map((e) => SoV2CompleteSummaryJenis.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      perBlok: perBlokList
          .map((e) => SoV2CompleteSummaryBlok.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      assignedUsersCount: (json['assignedUsersCount'] as num?)?.toInt() ?? 0,
    );
  }
}
