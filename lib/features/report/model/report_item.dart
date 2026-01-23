// lib/features/report/model/report_item.dart
import 'package:flutter/material.dart';

class ReportItem {
  final String title;
  final String subtitle;
  final String reportName;
  final IconData icon;
  final bool needsDateRange;

  const ReportItem({
    required this.title,
    required this.subtitle,
    required this.reportName,
    required this.icon,
    this.needsDateRange = true,
  });
}
