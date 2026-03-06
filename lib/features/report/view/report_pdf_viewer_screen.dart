// lib/features/report/view/report_pdf_viewer_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class ReportPdfViewerScreen extends StatefulWidget {
  final String title;
  final Uint8List initialPdfBytes;
  final bool isSingleDate;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Future<Uint8List> Function(DateTime start, DateTime end) onRegenerate;

  const ReportPdfViewerScreen({
    super.key,
    required this.title,
    required this.initialPdfBytes,
    required this.isSingleDate,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onRegenerate,
  });

  static Future<void> push({
    required BuildContext context,
    required String title,
    required Uint8List pdfBytes,
    required bool isSingleDate,
    required DateTime startDate,
    required DateTime endDate,
    required Future<Uint8List> Function(DateTime, DateTime) onRegenerate,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReportPdfViewerScreen(
          title: title,
          initialPdfBytes: pdfBytes,
          isSingleDate: isSingleDate,
          initialStartDate: startDate,
          initialEndDate: endDate,
          onRegenerate: onRegenerate,
        ),
      ),
    );
  }

  @override
  State<ReportPdfViewerScreen> createState() => _ReportPdfViewerScreenState();
}

class _ReportPdfViewerScreenState extends State<ReportPdfViewerScreen> {
  late Uint8List _pdfBytes;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _loading = false;
  int _previewKey = 0;

  static const _kDark = Color(0xFF0F172A);
  static const _kNavy = Color(0xFF1E293B);
  static const _kBlue = Color(0xFF0D47A1);
  static const _kSurface = Color(0xFFF8FAFC);
  static const _panelW = 300.0;

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.initialPdfBytes;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (widget.isSingleDate) {
        _startDate = picked;
        _endDate = picked;
      } else if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_startDate.isAfter(_endDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final bytes = await widget.onRegenerate(_startDate, _endDate);
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _previewKey++;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _print() async {
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes,
      name: widget.title,
    );
  }

  // ── Root build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          return isLandscape
              ? _buildLandscape(context)
              : _buildPortrait(context);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LANDSCAPE — PDF kiri, panel kanan
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLandscape(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildPreview(context, isLandscape: true)),
        SizedBox(
          width: _panelW,
          child: _buildPanel(context, isLandscape: true),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PORTRAIT — PDF atas, panel bawah
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPortrait(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildPreview(context, isLandscape: false)),
        _buildPanel(context, isLandscape: false),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PDF PREVIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPreview(BuildContext context, {required bool isLandscape}) {
    return Stack(
      children: [
        PdfPreview(
          key: ValueKey(_previewKey),
          build: (_) async => _pdfBytes,
          allowPrinting: false,
          allowSharing: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          scrollViewDecoration: const BoxDecoration(color: _kDark),
        ),

        // Top bar dengan close + judul
        Positioned(
          top: 0,
          left: 0,
          right: isLandscape ? null : 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              4,
              MediaQuery.of(context).padding.top,
              16,
              8,
            ),
            decoration: isLandscape
                ? null
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _kDark.withValues(alpha: 0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
            child: Row(
              mainAxisSize: isLandscape ? MainAxisSize.min : MainAxisSize.max,
              children: [
                _CloseBtn(onPressed: () => Navigator.of(context).pop()),
                if (!isLandscape) ...[
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
                ],
              ],
            ),
          ),
        ),

        // Loading overlay
        if (_loading)
          const ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Memuat laporan...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // Title badge (landscape)
        if (isLandscape)
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
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PANEL PARAMETER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPanel(BuildContext context, {required bool isLandscape}) {
    final bottom = MediaQuery.of(context).padding.bottom;

    Widget content = Column(
      mainAxisSize: isLandscape ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLandscape) _buildPanelHeader(context),

        // Scroll agar muat di portrait kecil
        if (isLandscape)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: _buildParamFields(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildParamFields(),
          ),

        Padding(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 18 : 16,
            12,
            isLandscape ? 18 : 16,
            (isLandscape ? 18 : 16) + bottom,
          ),
          child: _buildActions(),
        ),
      ],
    );

    if (isLandscape) {
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
        child: content,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
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
            content,
          ],
        ),
      );
    }
  }

  Widget _buildPanelHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        18,
        14,
      ),
      decoration: const BoxDecoration(
        color: _kNavy,
        border: Border(bottom: BorderSide(color: Color(0xFF2D3F55))),
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
              Icons.tune_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Pilih tanggal lalu tap Perbarui',
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

  Widget _buildParamFields() {
    if (widget.isSingleDate) {
      return _DateField(
        label: 'Tanggal',
        date: _startDate,
        onTap: () => _pickDate(isStart: true),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateField(
          label: 'Dari Tanggal',
          date: _startDate,
          onTap: () => _pickDate(isStart: true),
        ),
        const SizedBox(height: 10),
        _DateField(
          label: 'Sampai Tanggal',
          date: _endDate,
          onTap: () => _pickDate(isStart: false),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Perbarui
        ElevatedButton.icon(
          onPressed: _loading ? null : _reload,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Perbarui'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 13),
            elevation: 2,
            shadowColor: _kBlue.withValues(alpha: 0.4),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Cetak
        OutlinedButton.icon(
          onPressed: _loading ? null : _print,
          icon: const Icon(Icons.print_rounded, size: 18),
          label: const Text('Cetak'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBlue,
            side: BorderSide(color: _kBlue.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 13),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Date Field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  static const _kBlue = Color(0xFF0D47A1);
  static final _fmt = DateFormat('dd MMMM yyyy', 'id');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: _kBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt.format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kBlue,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Close Button ──────────────────────────────────────────────────────────────

class _CloseBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
    );
  }
}
