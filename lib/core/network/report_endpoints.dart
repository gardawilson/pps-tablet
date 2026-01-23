// lib/features/report/config/report_endpoints.dart
class ReportEndpoints {
  /// ✅ GANTI sesuai server kamu (untuk HP, JANGAN localhost)
  /// contoh: '192.168.10.100:44381'
  static const String hostWithPort = '192.168.10.100:3000';

  /// kalau server benar HTTPS, true. Kalau HTTP, false.
  static const bool useHttps = false;

  static Uri exportPdf(Map<String, String> query) {
    if (useHttps) {
      return Uri.https(hostWithPort, '/api/crystalreport/pps/export-pdf', query);
    }
    return Uri.http(hostWithPort, '/api/crystalreport/pps/export-pdf', query);
  }
}
