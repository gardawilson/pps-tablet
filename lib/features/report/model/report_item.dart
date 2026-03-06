// lib/features/report/model/report_item.dart
import 'package:flutter/material.dart';

enum ReportSource { crystalReport, ppsApi }

class ReportItem {
  final String title;
  final String subtitle;
  final String reportName;
  final IconData icon;
  final bool needsDateRange;
  final bool isSingleDate;
  final ReportSource source;

  /// Diisi saat [source] == [ReportSource.ppsApi].
  /// Berisi path endpoint, misal '/api/reports/pps/rekap-produksi/inject/pdf'.
  final String? ppsApiPath;

  const ReportItem({
    required this.title,
    required this.subtitle,
    required this.reportName,
    required this.icon,
    this.needsDateRange = true,
    this.isSingleDate = false,
    this.source = ReportSource.crystalReport,
    this.ppsApiPath,
  });
}
