import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
// Tambah ini agar bisa panggil LoadingDialog milikmu
import 'dart:async';
import '../../common/widgets/loading_dialog.dart'; // untuk unawaited (opsional, kalau mau rapih)

class PdfPrintService {
  PdfPrintService({
    required this.baseUrl,
    this.defaultSystem = 'pps',
    this.httpClient,
    this.getAuthHeader,
  });

  final String baseUrl;
  final String defaultSystem;
  final http.Client? httpClient;
  final Map<String, String> Function()? getAuthHeader;

  // =============== GENERIC URL BUILDER =================
  Uri buildUri({
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

  // =============== PUBLIC API (GENERIC) ===============
  Future<void> printReport80mm({
    required BuildContext context,
    required String reportName,
    required Map<String, String> query,
    String? system,
    String? saveNameHint,
    bool showLoading = true,
    String loadingMessage = 'Menyiapkan label…',
  }) async {
    final url = buildUri(reportName: reportName, query: query, system: system);
    await _withLoading(
      context: context,
      enabled: showLoading,
      message: loadingMessage,
      run: () => downloadAndPrint80mm(
        context: context,
        url: url,
        saveNameHint: saveNameHint ?? _inferName(reportName, query),
      ),
    );
  }

  /// Versi yang menerima URL langsung
  Future<void> downloadAndPrint80mm({
    required BuildContext context,
    required Uri url,
    String? saveNameHint,
    bool showLoading = false,              // default false, karena biasanya dipanggil via printReport80mm
    String loadingMessage = 'Memproses PDF…',
  }) async {
    Future<void> core() async {
      final bytes = await _download(url);
      final filename = _filenameFromHeaders(bytes.response, saveNameHint ?? 'Label.pdf');
      await _saveOriginalTemp(bytes.body, filename); // optional debug
      final rebuilt = await _remapPdfTo80mm(bytes.body);
      await _openNativePrintPreview(fileName: '80mm_$filename', pdfBytes: rebuilt);
    }

    if (showLoading) {
      await _withLoading(context: context, enabled: true, message: loadingMessage, run: core);
    } else {
      try {
        await core();
      } catch (e) {
        _showSnack(context, 'Print gagal: $e');
      }
    }
  }

  // =============== INTERNALS ===============
  String _inferName(String reportName, Map<String, String> query) {
    final keysPref = const ['NoBroker', 'NoWashing', 'NoProduksi', 'NoTrans', 'Nomor'];
    final key = keysPref.firstWhere((k) => query[k]?.isNotEmpty == true, orElse: () => '');
    final val = key.isEmpty ? '' : query[key]!;
    final safe = val.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    return '${reportName}_${safe.isEmpty ? DateTime.now().millisecondsSinceEpoch : safe}.pdf';
  }

  Future<_HttpBytes> _download(Uri url) async {
    final client = httpClient ?? http.Client();
    final headers = <String, String>{};
    if (getAuthHeader != null) headers.addAll(getAuthHeader!());

    final resp = await client.get(url, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('HTTP ${resp.statusCode} — tidak ada data.');
    }
    return _HttpBytes(resp, resp.bodyBytes);
  }

  Future<void> _saveOriginalTemp(Uint8List src, String filename) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(src, flush: true);
  }

  String _filenameFromHeaders(http.Response resp, String fallback) {
    final cd = resp.headers['content-disposition'] ?? '';
    final m = RegExp(r'filename\*?=([^;]+)', caseSensitive: false).firstMatch(cd);
    if (m != null) {
      var v = m.group(1)!.trim();
      v = v.replaceAll(RegExp(r"^UTF-8''"), '');
      v = v.replaceAll('"', '');
      return Uri.decodeFull(v);
    }
    return fallback;
  }

  Future<Uint8List> _remapPdfTo80mm(Uint8List srcBytes) async {
    final doc = pw.Document();
    final pageWidthPt = 80 * PdfPageFormat.mm;
    final rasters = Printing.raster(srcBytes, dpi: 150);

    await for (final r in rasters) {
      final pageHeightPt = pageWidthPt * (r.height / r.width);
      final png = await r.toPng();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain)),
        ),
      );
    }
    return doc.save();
  }

  Future<void> _openNativePrintPreview({
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    await Printing.layoutPdf(
      name: fileName,
      format: PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
      usePrinterSettings: true,
      onLayout: (_) async => pdfBytes,
    );
  }

  // ==== Loading helpers =====================================
  Future<T> _withLoading<T>({
    required BuildContext context,
    required Future<T> Function() run,
    bool enabled = true,
    String message = 'Memproses...',
  }) async {
    if (!enabled) return await run();

    final nav = Navigator.of(context, rootNavigator: true);
    bool shown = false;

    try {
      shown = true;
      // Jangan di-await supaya proses lanjut. Abaikan Future-nya (unawaited).
      // ignore: unawaited_futures
      showDialog(
        context: nav.context,
        barrierDismissible: false,
        builder: (_) => LoadingDialog(message: message),
      );

      final result = await run();
      return result;
    } catch (e) {
      _showSnack(context, e.toString());
      rethrow; // biar caller tahu kalau perlu
    } finally {
      if (shown && nav.canPop()) {
        // Tutup dialog loading
        nav.pop();
      }
    }
  }

  void _showSnack(BuildContext ctx, String msg) {
    final m = ScaffoldMessenger.maybeOf(ctx);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _HttpBytes {
  _HttpBytes(this.response, this.body);
  final http.Response response;
  final Uint8List body;
}
