import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../common/widgets/loading_dialog.dart';

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

  // Cache untuk printer yang dipilih
  Printer? _selectedPrinter;

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

  // =============== PUBLIC API (PREVIEW MODE) ===============
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

  /// Versi yang menerima URL langsung (PREVIEW MODE)
  Future<void> downloadAndPrint80mm({
    required BuildContext context,
    required Uri url,
    String? saveNameHint,
    bool showLoading = false,
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

  // =============== NEW: DIRECT PRINT MODE ===============

  /// Print langsung ke printer tanpa preview
  /// Returns true jika berhasil, false jika gagal
  Future<bool> directPrintReport80mm({
    required BuildContext context,
    required String reportName,
    required Map<String, String> query,
    String? system,
    bool autoSelectPrinter = true,
    bool showLoading = false,
    String loadingMessage = 'Mencetak label…',
    Function(String)? onError,
  }) async {
    final url = buildUri(reportName: reportName, query: query, system: system);

    return await directPrintFromUrl(
      context: context,
      url: url,
      autoSelectPrinter: autoSelectPrinter,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      onError: onError,
    );
  }

  /// Direct print dari URL
  /// Returns true jika berhasil, false jika gagal
  Future<bool> directPrintFromUrl({
    required BuildContext context,
    required Uri url,
    bool autoSelectPrinter = true,
    bool showLoading = false,
    String loadingMessage = 'Mencetak…',
    Function(String)? onError,
  }) async {
    Future<bool> core() async {
      try {
        // 1. Download PDF dari backend
        final bytes = await _download(url);

        // 2. Konversi ke 80mm
        final pdfBytes = await _remapPdfTo80mm(bytes.body);

        // 3. Print langsung
        final success = await _directPrintPdf(
          pdfBytes: pdfBytes,
          autoSelectPrinter: autoSelectPrinter,
        );

        return success;
      } catch (e) {
        final errorMsg = 'Print gagal: $e';
        if (onError != null) {
          onError(errorMsg);
        } else {
          _showSnack(context, errorMsg);
        }
        return false;
      }
    }

    if (showLoading) {
      return await _withLoading(
        context: context,
        enabled: true,
        message: loadingMessage,
        run: core,
      );
    } else {
      return await core();
    }
  }

  /// Core function untuk direct print
  Future<bool> _directPrintPdf({
    required Uint8List pdfBytes,
    bool autoSelectPrinter = true,
  }) async {
    try {
      // Jika auto select dan belum punya printer, cari printer thermal
      if (autoSelectPrinter && _selectedPrinter == null) {
        await _autoSelectThermalPrinter();
      }

      // Jika masih belum ada printer, gunakan default
      if (_selectedPrinter == null) {
        // Print ke printer default system
        final result = await Printing.directPrintPdf(
          printer: Printer(url: ''), // empty = use default
          onLayout: (_) => pdfBytes,
          format: PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
        );
        return result;
      } else {
        // Print ke printer yang sudah dipilih
        final result = await Printing.directPrintPdf(
          printer: _selectedPrinter!,
          onLayout: (_) => pdfBytes,
          format: PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
        );
        return result;
      }
    } catch (e) {
      debugPrint('❌ Direct print error: $e');
      return false;
    }
  }

  /// Auto-select printer thermal (RawBT, Panda, dll)
  Future<void> _autoSelectThermalPrinter() async {
    try {
      // Get list semua printer yang tersedia
      await Printing.listPrinters().then((printers) {
        if (printers.isEmpty) {
          debugPrint('⚠️ No printers found');
          return;
        }

        // Prioritas: cari printer dengan keyword thermal
        final keywords = [
          'rawbt',
          'panda',
          'prj',
          'thermal',
          'bluetooth',
          'bt',
          '80mm',
        ];

        for (final keyword in keywords) {
          final found = printers.firstWhere(
                (p) => p.name.toLowerCase().contains(keyword),
            orElse: () => Printer(url: ''),
          );

          if (found.url.isNotEmpty) {
            _selectedPrinter = found;
            debugPrint('✅ Auto-selected printer: ${found.name}');
            return;
          }
        }

        // Jika tidak ada yang match, gunakan printer pertama
        _selectedPrinter = printers.first;
        debugPrint('ℹ️ Using first available printer: ${printers.first.name}');
      });
    } catch (e) {
      debugPrint('⚠️ Error listing printers: $e');
      // Tetap lanjut, akan pakai default printer
    }
  }

  /// Manual select printer (untuk settings)
  Future<Printer?> selectPrinter(BuildContext context) async {
    try {
      final printers = await Printing.listPrinters();

      if (printers.isEmpty) {
        _showSnack(context, 'Tidak ada printer yang tersedia');
        return null;
      }

      // Show dialog untuk pilih printer
      final selected = await showDialog<Printer>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pilih Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: printers.length,
              itemBuilder: (_, i) {
                final p = printers[i];
                final isSelected = _selectedPrinter?.url == p.url;

                return ListTile(
                  leading: Icon(
                    Icons.print,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(p.url),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.pop(ctx, p),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL'),
            ),
          ],
        ),
      );

      if (selected != null) {
        _selectedPrinter = selected;
        debugPrint('✅ Manually selected printer: ${selected.name}');
      }

      return selected;
    } catch (e) {
      _showSnack(context, 'Error: $e');
      return null;
    }
  }

  /// Reset printer selection (gunakan auto-select lagi)
  void resetPrinterSelection() {
    _selectedPrinter = null;
    debugPrint('🔄 Printer selection reset');
  }

  /// Get current selected printer info
  String? get selectedPrinterName => _selectedPrinter?.name;
  bool get hasPrinterSelected => _selectedPrinter != null;

  // =============== INTERNALS ===============
  String _inferName(String reportName, Map<String, String> query) {
    final keysPref = const ['NoBroker', 'NoWashing', 'NoProduksi', 'NoTrans', 'Nomor', 'NoBJ'];
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
      rethrow;
    } finally {
      if (shown && nav.canPop()) {
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