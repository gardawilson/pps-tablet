import 'package:flutter/material.dart';

enum SoV2Status {
  notStarted,
  inProgress,
  completed;

  static SoV2Status fromApi(String value) {
    switch (value) {
      case 'in_progress':
        return SoV2Status.inProgress;
      case 'completed':
        return SoV2Status.completed;
      case 'not_started':
      default:
        return SoV2Status.notStarted;
    }
  }

  String get label {
    switch (this) {
      case SoV2Status.notStarted:
        return 'Belum Mulai';
      case SoV2Status.inProgress:
        return 'Sedang Berjalan';
      case SoV2Status.completed:
        return 'Selesai';
    }
  }

  Color get color {
    switch (this) {
      case SoV2Status.notStarted:
        return const Color(0xFF6B7280);
      case SoV2Status.inProgress:
        return const Color(0xFF1E6FD9);
      case SoV2Status.completed:
        return const Color(0xFF0A7349);
    }
  }
}

class SoV2Kategori {
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String? stockOpnameNo;
  final SoV2Status status;
  final int labelCount;
  final int scannedCount;

  SoV2Kategori({
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.stockOpnameNo,
    required this.status,
    required this.labelCount,
    required this.scannedCount,
  });

  double get progress => labelCount > 0 ? scannedCount / labelCount : 0;

  factory SoV2Kategori.fromJson(Map<String, dynamic> json) {
    return SoV2Kategori(
      categoryId: json['categoryId'] as int,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      stockOpnameNo: json['stockOpnameNo']?.toString(),
      status: SoV2Status.fromApi(json['status']?.toString() ?? 'not_started'),
      labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      scannedCount: (json['scannedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
