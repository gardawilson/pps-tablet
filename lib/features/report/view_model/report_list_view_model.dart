// lib/features/report/view_model/report_list_view_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/report_endpoints.dart';
import '../model/report_item.dart';
import '../service/report_pdf_service.dart';

class ReportListViewModel extends ChangeNotifier {
  ReportListViewModel({
    required List<ReportItem> initialReports,
    required ReportPdfService pdfService,
    required this.username,
  })  : _pdfService = pdfService,
        _allReports = initialReports,
        _filteredReports = initialReports;

  final ReportPdfService _pdfService;
  final String username;

  final List<ReportItem> _allReports;
  List<ReportItem> _filteredReports;

  List<ReportItem> get filteredReports => _filteredReports;

  String _search = '';
  String get search => _search;

  set search(String value) {
    _search = value;
    _filterReports();
  }

  bool _loading = false;
  bool get loading => _loading;

  final df = DateFormat('yyyy-MM-dd');

  void _filterReports() {
    if (_search.isEmpty) {
      _filteredReports = _allReports;
    } else {
      final query = _search.toLowerCase();
      _filteredReports = _allReports.where((r) {
        return r.title.toLowerCase().contains(query) ||
            r.subtitle.toLowerCase().contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Uri _buildUri(String reportName, DateTime startDate, DateTime endDate) {
    final qp = <String, String>{
      'reportName': reportName,
      'StartDate': df.format(startDate),
      'EndDate': df.format(endDate),
      'Username': username,
    };
    return ReportEndpoints.exportPdf(qp);
  }

  String _buildFileName(String reportName, DateTime startDate, DateTime endDate) {
    final safe = reportName.replaceAll(RegExp(r'[^\w\-]+'), '_');
    return '${safe}_${df.format(startDate)}_${df.format(endDate)}.pdf';
  }

  Future<void> generateReport({
    required String reportName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final uri = _buildUri(reportName, startDate, endDate);
      final filename = _buildFileName(reportName, startDate, endDate);

      debugPrint('🧾 [REPORT] URL => $uri');

      await _pdfService.downloadSaveAndOpenPdf(
        uri: uri,
        filename: filename,
      );
    } catch (e) {
      debugPrint('❌ [REPORT] Error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}