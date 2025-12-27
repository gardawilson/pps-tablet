import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk print label via RawBT app
/// Menggunakan Android Intent untuk open file dengan RawBT
class RawBTPrintService {
  RawBTPrintService({
    required this.baseUrl,
    this.defaultSystem = 'pps',
    this.httpClient,
    this.getAuthHeader,
  });

  final String baseUrl;
  final String defaultSystem;
  final http.Client? httpClient;
  final Map<String, String> Function()? getAuthHeader;

  // =============== BUILDER URL =================

  /// Build URL for PDF export
  Uri buildPdfUri({
    required String reportName,
    required Map<String, String> query,
    String? system,
  }) {
    final u = Uri.parse('$baseUrl/api/crystalreport/${system ?? defaultSystem}/export-pdf');
    return u.replace(queryParameters: {
      'reportName': reportName,
      ...query,
    });
  }

  // =============== STORAGE PERMISSIONS =================

  /// Request storage permissions for saving PDF
  /// Android 13+ tidak perlu storage permission untuk app-specific directory
  Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ (API 33+) TIDAK PERLU storage permission
        // karena kita pakai app-specific directory (getApplicationDocumentsDirectory)
        // yang otomatis accessible tanpa permission

        // Langsung return true, tidak perlu request permission
        debugPrint('✅ Storage access OK (app-specific directory)');
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error checking storage: $e');
      return true; // Return true anyway, biar lanjut save
    }
  }

  // =============== PRINT VIA RAWBT APP =================

  /// Print label dengan open file via RawBT app
  /// Returns: success status
  Future<bool> printLabelViaRawBT({
    required String reportName,
    required Map<String, String> query,
    String? system,
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    try {
      if (onStatus != null) onStatus('Mengunduh PDF...');

      // 1. Download PDF
      final url = buildPdfUri(reportName: reportName, query: query, system: system);
      final pdfBytes = await _downloadPdf(url);

      if (onStatus != null) onStatus('Menyimpan file...');

      // 2. Save to local storage
      final filePath = await _savePdfToLocal(pdfBytes, query);

      if (onStatus != null) onStatus('Membuka RawBT...');

      // 3. Open with RawBT app
      final opened = await _openWithRawBT(filePath);

      if (opened) {
        if (onStatus != null) onStatus('✅ File dibuka dengan RawBT');
        return true;
      } else {
        if (onError != null) {
          onError('Gagal membuka RawBT. Pastikan RawBT app sudah terinstall.');
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Print via RawBT error: $e');
      if (onError != null) onError('Error: ${e.toString()}');
      return false;
    }
  }

  // =============== INTERNALS =================

  /// Download PDF from backend
  Future<Uint8List> _downloadPdf(Uri url) async {
    final client = httpClient ?? http.Client();
    final headers = <String, String>{};
    if (getAuthHeader != null) headers.addAll(getAuthHeader!());

    final resp = await client.get(url, headers: headers).timeout(
      const Duration(seconds: 30),
    );

    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('HTTP ${resp.statusCode} — tidak ada data PDF.');
    }

    debugPrint('📄 PDF downloaded: ${resp.bodyBytes.length} bytes');
    return resp.bodyBytes;
  }

  /// Save PDF to local storage
  Future<String> _savePdfToLocal(
      Uint8List pdfBytes,
      Map<String, String> query,
      ) async {
    try {
      // Get app documents directory (tidak perlu permission di Android 13+)
      // Path ini: /data/data/com.example.pps_tablet/app_flutter/
      final directory = await getApplicationDocumentsDirectory();

      // Create filename dari NoBJ
      final noBJ = query['NoBJ'] ?? 'label_${DateTime.now().millisecondsSinceEpoch}';
      final safeFileName = noBJ.replaceAll(RegExp(r'[^\w\s-]'), '_');

      final filePath = '${directory.path}/$safeFileName.pdf';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      debugPrint('💾 PDF saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error saving PDF: $e');
      rethrow;
    }
  }

  /// Open file with RawBT app using Intent
  Future<bool> _openWithRawBT(String filePath) async {
    try {
      debugPrint('📱 Opening file with RawBT: $filePath');

      //Gunakan open_file package untuk trigger "Open with" dialog
      final result = await OpenFile.open(
        filePath,
        type: 'application/pdf',
        linuxDesktopName: 'rawbt', // Hint untuk RawBT app
      );

      debugPrint('📱 OpenFile result: ${result.type} - ${result.message}');

      // result.type values:
      // - done: File opened successfully
      // - fileNotFound: File not found
      // - noAppToOpen: No app can open this file
      // - permissionDenied: Permission denied
      // - unknown: Unknown error

      if (result.type == ResultType.done) {
        debugPrint('✅ File opened successfully');
        return true;
      } else {
        debugPrint('❌ Failed to open file: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      return false;
    }
  }

  /// Cleanup old PDF files (optional - panggil periodic)
  Future<void> cleanupOldPdfs({int maxAgeHours = 24}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();

      final files = directory.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inHours > maxAgeHours) {
            await file.delete();
            debugPrint('🗑️ Deleted old PDF: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning up PDFs: $e');
    }
  }

  /// Dispose service
  void dispose() {
    debugPrint('🧹 RawBTPrintService disposed');
  }
}