// lib/features/report/service/report_pdf_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ReportPdfService {
  ReportPdfService({
    http.Client? client,
    Map<String, String> Function()? getAuthHeader,
  })  : _client = client ?? http.Client(),
        _getAuthHeader = getAuthHeader;

  final http.Client _client;
  final Map<String, String> Function()? _getAuthHeader;

  Future<void> downloadSaveAndOpenPdf({
    required Uri uri,
    required String filename,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/pdf',
      if (_getAuthHeader != null) ..._getAuthHeader!(),
    };

    final resp = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    final ct = resp.headers['content-type'] ?? '';
    if (resp.statusCode != 200) {
      final preview = resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception('HTTP ${resp.statusCode}\n$preview');
    }

    final bytes = resp.bodyBytes;
    if (bytes.isEmpty) throw Exception('PDF kosong (bytes=0)');

    // Validasi cepat PDF signature
    final head = String.fromCharCodes(bytes.take(4));
    if (head != '%PDF') {
      throw Exception('Data bukan PDF valid. Head="$head". content-type="$ct"');
    }

    final file = await _saveTemp(bytes: bytes, filename: filename);

    final result = await OpenFilex.open(file.path, type: 'application/pdf');
    if (result.type != ResultType.done) {
      throw Exception('Open file gagal: ${result.message}');
    }
  }

  Future<File> _saveTemp({
    required Uint8List bytes,
    required String filename,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
