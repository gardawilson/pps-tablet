// lib/features/stock_opname_v2/model/so_v2_scan_summary.dart

/// Satu baris performa scan per user — bagian dari [SoV2ScanSummary].
class SoV2ScanSummaryUser {
  final String username;
  final String fullName;
  final int labelCount;
  final DateTime? firstScanAt;
  final DateTime? lastScanAt;
  final double totalWeight;

  const SoV2ScanSummaryUser({
    required this.username,
    required this.fullName,
    required this.labelCount,
    this.firstScanAt,
    this.lastScanAt,
    required this.totalWeight,
  });

  factory SoV2ScanSummaryUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return SoV2ScanSummaryUser(
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      firstScanAt: parseDate(json['firstScanAt']),
      lastScanAt: parseDate(json['lastScanAt']),
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Ringkasan performa scan per user — GET
/// `/stock-opname-v2/transaksi/:stockOpnameNo/scan-summary`. Dipakai buat
/// dialog "siapa scan berapa banyak" setelah SO ditandai selesai.
class SoV2ScanSummary {
  final String stockOpnameNo;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final bool isComplete;
  final DateTime? completedAt;
  final List<SoV2ScanSummaryUser> data;
  final int totalUsers;
  final int totalScanned;

  const SoV2ScanSummary({
    required this.stockOpnameNo,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.isComplete,
    this.completedAt,
    required this.data,
    required this.totalUsers,
    required this.totalScanned,
  });

  factory SoV2ScanSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final userList = (json['data'] ?? []) as List;

    return SoV2ScanSummary(
      stockOpnameNo: json['stockOpnameNo']?.toString() ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      isComplete: json['isComplete'] == true,
      completedAt: parseDate(json['completedAt']),
      data: userList
          .map((e) => SoV2ScanSummaryUser.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalScanned: (json['totalScanned'] as num?)?.toInt() ?? 0,
    );
  }
}
