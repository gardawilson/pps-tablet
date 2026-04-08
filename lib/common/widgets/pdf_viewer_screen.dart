import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import '../../common/widgets/master_printer_selector.dart';
import '../../core/utils/bt_print_service.dart';

/// In-app PDF viewer + panel Bluetooth print.
///
/// **Landscape tablet**: two-column — PDF preview (kiri) + kontrol (kanan).
/// **Portrait**        : stacked — PDF preview (atas) + panel (bawah).
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final Uint8List pdfBytes;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfBytes,
  });

  static Future<PrintOutcome?> push({
    required BuildContext context,
    required String title,
    required Uint8List pdfBytes,
  }) {
    return Navigator.of(context, rootNavigator: true).push<PrintOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PdfViewerScreen(title: title, pdfBytes: pdfBytes),
      ),
    );
  }

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _printerMac;
  String? _printerName;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _kDark = Color(0xFF0F172A); // preview bg
  static const _kNavy = Color(0xFF1E293B); // right panel header bg
  static const _kBlue = Color(0xFF0C66E4); // primary
  static const _kSurface = Color(0xFFF8FAFC); // right panel bg

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
  }

  // ── Printer ───────────────────────────────────────────────────────────────

  Future<void> _loadSavedPrinter() async {
    final saved = await BtPrintService.loadSavedPrinter();
    if (saved != null && mounted) {
      setState(() {
        _printerMac = saved.mac;
        _printerName = saved.name;
      });
    }
  }

  Future<void> _selectPrinter() async {
    final selection = await MasterPrinterSelector.show(
      context: context,
      currentMac: _printerMac,
    );
    if (selection == null || !mounted) return;
    setState(() {
      _printerMac = selection.mac;
      _printerName = selection.printerName;
    });
  }

  // ── Print ─────────────────────────────────────────────────────────────────

  void _doPrint() {
    if (_printerMac == null) return;
    Navigator.of(context).pop(
      PrintOutcome(
        mac: _printerMac!,
        printerName: _printerName ?? _printerMac!,
      ),
    );
  }

  // ── Root build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          return isLandscape ? _buildLandscape() : _buildPortrait();
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LANDSCAPE — two-column
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscape() {
    final hasPrinter = _printerMac != null;
    const panelW = 340.0;

    return Row(
      children: [
        Expanded(child: _buildLandscapePreview()),
        SizedBox(width: panelW, child: _buildLandscapePanel(hasPrinter)),
      ],
    );
  }

  Widget _buildLandscapePreview() {
    return Stack(
      children: [
        PdfPreview(
          build: (_) async => widget.pdfBytes,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          maxPageWidth: 300,
          scrollViewDecoration: const BoxDecoration(color: _kDark),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _CloseButton(onPressed: () => Navigator.of(context).pop()),
        ),

        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 13,
                  color: Colors.white54,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapePanel(bool hasPrinter) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPanelHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocumentCard(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('PRINTER'),
                  const SizedBox(height: 8),
                  _buildPrinterTile(hasPrinter),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18 + MediaQuery.of(context).padding.bottom,
            ),
            child: _buildPrintButton(hasPrinter),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        18,
        14,
      ),
      decoration: const BoxDecoration(
        color: _kNavy,
        border: Border(bottom: BorderSide(color: Color(0xFF2D3F55), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.print_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cetak Label',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Thermal · 80 mm',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DOKUMEN',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PORTRAIT — stacked
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPortrait() {
    final hasPrinter = _printerMac != null;
    return Column(
      children: [
        Expanded(child: _buildPortraitPreview()),
        _buildPortraitPanel(hasPrinter),
      ],
    );
  }

  Widget _buildPortraitPreview() {
    return Stack(
      children: [
        PdfPreview(
          build: (_) async => widget.pdfBytes,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          maxPageWidth: 300,
          scrollViewDecoration: const BoxDecoration(color: _kDark),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              4,
              MediaQuery.of(context).padding.top,
              16,
              8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kDark.withValues(alpha: 0.95), Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                _CloseButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 12,
                        color: Colors.white54,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '80mm',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitPanel(bool hasPrinter) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 2),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPrinterTile(hasPrinter),
                const SizedBox(height: 12),
                _buildPrintButton(hasPrinter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────

  Widget _buildPrinterTile(bool hasPrinter) {
    final bg = hasPrinter ? Colors.green.shade50 : Colors.amber.shade50;
    final border = hasPrinter ? Colors.green.shade200 : Colors.amber.shade300;
    final iconBg = hasPrinter ? Colors.green.shade100 : Colors.amber.shade100;
    final iconColor = hasPrinter
        ? Colors.green.shade700
        : Colors.amber.shade700;
    final labelColor = hasPrinter
        ? Colors.green.shade600
        : Colors.amber.shade700;
    final nameColor = hasPrinter
        ? Colors.green.shade900
        : Colors.amber.shade900;
    final btnBg = hasPrinter ? Colors.green.shade100 : Colors.amber.shade100;
    final btnFg = hasPrinter ? Colors.green.shade800 : Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bluetooth_rounded, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasPrinter ? 'PRINTER TERPILIH' : 'BELUM ADA PRINTER',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasPrinter
                      ? (_printerName ?? _printerMac!)
                      : 'Tap PILIH untuk memilih printer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _selectPrinter,
            style: TextButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              hasPrinter ? 'GANTI' : 'PILIH',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton(bool hasPrinter) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasPrinter ? _doPrint : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade100,
          disabledForegroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: hasPrinter ? 4 : 0,
          shadowColor: _kBlue.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'CETAK LABEL',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Close Button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
        ),
        tooltip: 'Tutup',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}

// ── Bluetooth Printer Selector Sheet ──────────────────────────────────────────

