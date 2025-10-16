import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';
import '../model/washing_header_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart'; // PdfPageFormat
import 'package:printing/printing.dart';


class WashingRowPopover extends StatelessWidget {
  final WashingHeader header;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const WashingRowPopover({
    super.key,
    required this.header,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  void _runAndClose(VoidCallback action) {
    onClose();
    action();
  }

  Future<void> _copyOnly(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: header.noWashing));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NoWashing "${header.noWashing}" disalin'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 0, thickness: 0.6, color: Colors.grey.shade300);

    // ⬇️ ambil izin sekali
    final perm = context.watch<PermissionViewModel>();
    final canEdit   = perm.can('label_washing:update');
    final canDelete = perm.can('label_washing:delete');

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header info - Blue Gradient Design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(
                      Icons.label,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header.noWashing,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          header.namaJenisPlastik,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Copy Button
                  IconButton(
                    tooltip: 'Salin NoWashing',
                    icon: Icon(Icons.copy_outlined, color: Colors.white.withOpacity(0.9)),
                    onPressed: () => _copyOnly(context),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            divider,

            // Edit (dikunci oleh permission)
            _MenuTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              enabled: canEdit,
              tooltipWhenDisabled: 'Tidak punya izin edit',
              onTap: () => _runAndClose(onEdit),
            ),
            divider,

            // Print (contoh tanpa izin)
            _MenuTile(
              icon: Icons.print_outlined,
              label: 'Print (80mm)',
              enabled: true,
              onTap: () => _runAndClose(() async {
                final rootCtx = Navigator.of(context, rootNavigator: true).context;
                await _printPdfNative80mm(
                  rootCtx,
                  noWashing: header.noWashing,
                );
              }),
            ),

            divider,

            // Hapus (destruktif, dikunci permission)
            _MenuTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              enabled: canDelete,
              tooltipWhenDisabled: 'Tidak punya izin hapus',
              iconColor: canDelete ? Colors.red.shade600 : null,
              textStyle: TextStyle(
                color: canDelete ? Colors.red.shade600 : Colors.grey,
              ),
              onTap: () => _runAndClose(onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile menu dengan state enabled/disabled yang jelas
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltipWhenDisabled;
  final Color? iconColor;
  final TextStyle? textStyle;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tooltipWhenDisabled,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = enabled ? (iconColor ?? theme.iconTheme.color) : Colors.grey;
    final effectiveTextStyle = (textStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      color: enabled ? (textStyle?.color ?? theme.textTheme.bodyMedium?.color) : Colors.grey,
    );

    final tile = InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: effectiveIconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: effectiveTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Tooltip saat disabled (opsional)
    if (!enabled && (tooltipWhenDisabled?.isNotEmpty ?? false)) {
      return Tooltip(message: tooltipWhenDisabled!, child: Opacity(opacity: 0.55, child: tile));
    }
    return tile;
  }
}


// URL builder (same as yours)
Uri _buildPdfUri(String noWashing) {
  return Uri.parse('http://192.168.10.100:3000/api/crystalreport/pps/export-pdf')
      .replace(queryParameters: {
    'reportName': 'CrLabelPalletWashing',
    'NoWashing': noWashing,
  });
}

void _showSnack(BuildContext ctx, String msg) {
  final m = ScaffoldMessenger.maybeOf(ctx);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(content: Text(msg)));
}

String _filenameFromHeaders(http.Response resp, String fallback) {
  final cd = resp.headers['content-disposition'] ?? '';
  final match = RegExp(r'filename\*?=([^;]+)', caseSensitive: false).firstMatch(cd);
  if (match != null) {
    var v = match.group(1)!.trim();
    v = v.replaceAll(RegExp(r"^UTF-8''"), '');
    v = v.replaceAll('"', '');
    return Uri.decodeFull(v);
  }
  return fallback;
}

// Rebuild any incoming PDF as 80mm wide, height per page auto (roll-friendly)
Future<Uint8List> _remapPdfTo80mm(Uint8List srcBytes) async {
  final doc = pw.Document();
  final pageWidthPt = 80 * PdfPageFormat.mm;

  // Render each source page -> raster (bitmap)
  final rasters = Printing.raster(srcBytes, dpi: 150); // thermal-friendly DPI
  await for (final r in rasters) {
    final pageHeightPt = pageWidthPt * (r.height / r.width); // preserve aspect
    final png = await r.toPng();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Center(
          child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
        ),
      ),
    );
  }
  return doc.save();
}

// Download -> rebuild to 80mm -> open native print dialog
Future<void> _printPdfNative80mm(
    BuildContext safeContext, {
      required String noWashing,
    }) async {
  final url = _buildPdfUri(noWashing);
  try {
    // 1) download
    final resp = await http.get(url);
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw Exception('PDF tidak ditemukan (status ${resp.statusCode})');
    }

    // (optional) simpan original utk inspeksi
    final safeName = noWashing.replaceAll(RegExp(r'[^\w\-.]+'), '_');
    final suggested = _filenameFromHeaders(resp, 'Label_$safeName.pdf');
    final dir = await getTemporaryDirectory();
    final original = File('${dir.path}/$suggested');
    await original.writeAsBytes(resp.bodyBytes, flush: true);

    // 2) rebuild as 80mm
    final rebuiltBytes = await _remapPdfTo80mm(resp.bodyBytes);

    // 3) native print preview; format hint set to 80mm x tall
    await Printing.layoutPdf(
      name: '80mm_$suggested',
      format: PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
      usePrinterSettings: true,
      onLayout: (PdfPageFormat _) async => rebuiltBytes,
    );
  } catch (e) {
    _showSnack(safeContext, 'Error: $e');
  }
}