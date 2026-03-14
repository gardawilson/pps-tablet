import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bt_print_service.dart';
import '../../core/utils/master_printer_repository.dart';

/// Hasil dari PDF viewer screen — berisi printer yang dipilih user saat CETAK.
/// Null jika user menutup layar tanpa mencetak.
class PrintOutcome {
  final String mac;
  final String printerName;

  const PrintOutcome({required this.mac, required this.printerName});
}

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
    final repo = context.read<MasterPrinterRepository>();
    await showDialog<void>(
      context: context,
      builder: (_) => _BtPrinterSheet(
        currentMac: _printerMac,
        repository: repo,
        onSelected: (mac, name) => setState(() {
          _printerMac = mac;
          _printerName = name;
        }),
      ),
    );
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

class _BtPrinterSheet extends StatefulWidget {
  final String? currentMac;
  final void Function(String mac, String name) onSelected;
  final MasterPrinterRepository repository;

  const _BtPrinterSheet({
    required this.currentMac,
    required this.onSelected,
    required this.repository,
  });

  @override
  State<_BtPrinterSheet> createState() => _BtPrinterSheetState();
}

class _BtPrinterSheetState extends State<_BtPrinterSheet> {
  List<BluetoothInfo> _devices = [];
  Map<String, String> _aliases = {};
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final granted = await BtPrintService.ensurePermissions();
      if (!mounted) return;
      if (!granted) {
        setState(() {
          _loading = false;
          _errorMsg =
              'Permission "Perangkat Terdekat" (Nearby Devices) belum diizinkan.\n\n'
              'Buka Settings → Aplikasi → PPS Tablet → Izin → aktifkan Perangkat Terdekat, lalu kembali.';
        });
        return;
      }
      final results = await Future.wait([
        BtPrintService.getPairedDevices(),
        widget.repository.fetchAliases(),
      ]);
      if (mounted) {
        setState(() {
          _devices = results[0] as List<BluetoothInfo>;
          _aliases = results[1] as Map<String, String>;
          _loading = false;
          if (_devices.isEmpty) {
            _errorMsg =
                'Tidak ada perangkat Bluetooth yang sudah di-pair.\n'
                'Pair printer di Settings > Bluetooth Android terlebih dahulu.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Gagal mengambil daftar perangkat: $e';
        });
      }
    }
  }

  /// Tampilkan dialog untuk memberi nama alias pada printer
  Future<void> _editAlias(BluetoothInfo device) async {
    final mac = device.macAdress;
    final currentAlias = _aliases[mac] ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _AliasEditDialog(
        mac: mac,
        btName: device.name,
        currentAlias: currentAlias,
      ),
    );

    if (result == null || !mounted) return;

    if (result.isEmpty) {
      await widget.repository.remove(mac);
    } else {
      await widget.repository.upsert(mac, result);
    }

    if (!mounted) return;
    final updated = await widget.repository.fetchAliases();
    if (mounted) setState(() => _aliases = updated);
  }

  /// Nama yang ditampilkan untuk printer: alias (jika ada) → nama BT → MAC
  String _displayName(BluetoothInfo d) {
    return _aliases[d.macAdress] ?? (d.name.isNotEmpty ? d.name : d.macAdress);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Printer Bluetooth',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Menampilkan perangkat yang sudah di-pair',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),

            // ── Body ────────────────────────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Mengambil daftar perangkat…',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth_disabled_rounded,
                        size: 28,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _errorMsg!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    final isSelected = d.macAdress == widget.currentMac;
                    final hasAlias = _aliases.containsKey(d.macAdress);
                    final displayName = _displayName(d);
                    return ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 4,
                        right: 0,
                        top: 2,
                        bottom: 2,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.print_rounded,
                          size: 20,
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade500,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (hasAlias)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Tooltip(
                                message: 'Sudah diberi nama',
                                child: Icon(
                                  Icons.label_rounded,
                                  size: 14,
                                  color: Colors.blue.shade300,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        hasAlias && d.name.isNotEmpty
                            ? '${d.name} · ${d.macAdress}'
                            : d.macAdress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editAlias(d),
                            icon: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            tooltip: 'Beri nama',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.blue.shade600,
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                        final mac = d.macAdress;
                        final name = _displayName(d);
                        await BtPrintService.savePrinter(mac: mac, name: name);
                        if (!context.mounted) return;
                        widget.onSelected(mac, name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AliasEditDialog extends StatefulWidget {
  final String mac;
  final String btName;
  final String currentAlias;

  const _AliasEditDialog({
    required this.mac,
    required this.btName,
    required this.currentAlias,
  });

  @override
  State<_AliasEditDialog> createState() => _AliasEditDialogState();
}

class _AliasEditDialogState extends State<_AliasEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAlias);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Beri Nama Printer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MAC: ${widget.mac}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (widget.btName.isNotEmpty)
              Text(
                'Nama BT: ${widget.btName}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nama kustom (mis. Printer 1)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('BATAL'),
        ),
        if (widget.currentAlias.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('HAPUS ALIAS'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('SIMPAN'),
        ),
      ],
    );
  }
}
