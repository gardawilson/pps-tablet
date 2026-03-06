// lib/features/report/config/report_endpoints.dart
class ReportEndpoints {
  /// Crystal Report server
  static const String hostWithPort = '192.168.10.100:3000';

  /// PPS API server
  static const String ppsApiHost = '192.168.11.50:8000';

  static Uri exportPdf(Map<String, String> query) {
    return Uri.http(hostWithPort, '/api/crystalreport/pps/export-pdf', query);
  }

  /// PPS API - single date report. [path] adalah path endpoint,
  /// [reportDate] format: dd-MM-yyyy
  static Uri ppsApiPdf(String path, String reportDate) {
    return Uri.http(ppsApiHost, path, {'report_date': reportDate});
  }
}
