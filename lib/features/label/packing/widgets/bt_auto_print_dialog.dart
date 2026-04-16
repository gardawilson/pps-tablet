import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/widgets/info_box.dart';
import '../../../../common/widgets/master_printer_selector.dart';
import '../../../../common/widgets/printer_selector_tile.dart';
import '../../../../core/utils/bt_print_service.dart';
import '../../../../core/utils/device_printer_service.dart';

typedef GenerateSameCallback = Future<List<dynamic>> Function();

class BtAutoPrintDialog extends StatefulWidget {
  final List<dynamic> headers;

  /// Total label berhasil dibuat (dari backend create)
  final int count;

  final String reportName;
  final String baseUrl;
  final GenerateSameCallback onGenerateSame;
  final String labelQueryKey;
  final String Function(dynamic header) labelExtractor;
  final Future<void> Function(String code)? markAsPrinted;

  const BtAutoPrintDialog({
    super.key,
    required this.headers,
    required this.count,
    required this.reportName,
    required this.baseUrl,
    required this.onGenerateSame,
    required this.labelQueryKey,
    required this.labelExtractor,
    this.markAsPrinted,
  });

  @override
  State<BtAutoPrintDialog> createState() => _BtAutoPrintDialogState();
}

class _BtAutoPrintDialogState extends State<BtAutoPrintDialog> {
  int _currentIndex = 0;

  bool _busy = false;
  bool _lastPrintSuccess = false;

  String _status = 'Pilih printer lalu tap PRINT untuk mencetak.';
  String? _error;

  late final BtPrintService _btService;
  late List<dynamic> _headers;
  late int _count;

  // Printer yang tersimpan / dipilih
  String? _printerId;
  String? _printerMac;
  String? _printerName;

  @override
  void initState() {
    super.initState();
    _btService = BtPrintService(baseUrl: widget.baseUrl, defaultSystem: 'pps');

    _headers = List<dynamic>.from(widget.headers);
    _count = widget.count > 0 ? widget.count : _headers.length;
    if (_headers.length > _count) _count = _headers.length;

    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final saved = await DevicePrinterService.loadDefaultPrinter();
    if (saved != null && mounted) {
      setState(() {
        _printerId = saved.id;
        _printerMac = saved.mac;
        _printerName = saved.name;
        _status = 'Siap mencetak ke ${saved.name}.';
      });
      return;
    }
    final legacy = await BtPrintService.loadSavedPrinter();
    if (legacy != null && mounted) {
      setState(() {
        _printerMac = legacy.mac;
        _printerName = legacy.name;
        _status = 'Siap mencetak ke ${legacy.name}.';
      });
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  String get _currentLabel {
    if (_headers.isEmpty || _currentIndex >= _headers.length) return '-';
    return widget.labelExtractor(_headers[_currentIndex]);
  }

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex < _headers.length - 1;
  int get _pos => _headers.isEmpty ? 0 : (_currentIndex + 1);

  Color _toneColor() {
    if (_error != null) return Colors.red.shade700;
    if (_lastPrintSuccess) return Colors.green.shade700;
    return Colors.blue.shade700;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Title =====
              Row(
                children: [
                  Icon(Icons.print, color: tone),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cetak Label (Auto)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Current label =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_pos/$_count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                          _currentLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy label',
                      onPressed: (_currentLabel == '-' || _busy)
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(text: _currentLabel),
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Tersalin: $_currentLabel'),
                                  duration: const Duration(milliseconds: 800),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Printer selector row =====
              _buildPrinterRow(),

              const SizedBox(height: 10),

              // ===== Status / Error =====
              InfoBox(
                height: 78,
                busy: _busy,
                isError: _error != null,
                icon: _error != null
                    ? Icons.error_outline
                    : (_lastPrintSuccess
                          ? Icons.check_circle_outline
                          : Icons.info_outline),
                iconColor: _error != null ? Colors.red.shade700 : tone,
                text: _error ?? _status,
              ),

              const SizedBox(height: 14),

              // ===== PRINT button =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_busy || _printerMac == null) ? null : _doPrint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PRINT',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ===== Prev / Next =====
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : (_hasPrev ? _prev : null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('SEBELUMNYA'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : (_hasNext ? _next : null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('BERIKUTNYA'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Generate new label (same data) =====
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _generateNewLabelSameData,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BUAT LABEL BARU (DATA SAMA)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterRow() {
    return PrinterSelectorTile(
      printerName: _printerName,
      printerMac: _printerMac,
      printerId: _printerId,
      onSelect: _selectPrinter,
      disabled: _busy,
      compact: true,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _prev() {
    if (!_hasPrev) return;
    setState(() {
      _currentIndex--;
      _error = null;
      _lastPrintSuccess = false;
      _status = _printerName != null
          ? 'Siap mencetak ke $_printerName.'
          : 'Pilih printer lalu tap PRINT untuk mencetak.';
    });
  }

  void _next() {
    if (!_hasNext) return;
    setState(() {
      _currentIndex++;
      _error = null;
      _lastPrintSuccess = false;
      _status = _printerName != null
          ? 'Siap mencetak ke $_printerName.'
          : 'Pilih printer lalu tap PRINT untuk mencetak.';
    });
  }

  /// Buka dialog MasterPrinterSelector untuk memilih printer Bluetooth
  Future<void> _selectPrinter() async {
    final outcome = await MasterPrinterSelector.show(
      context: context,
      currentMac: _printerMac,
    );

    if (outcome == null) return;

    setState(() {
      _printerId = outcome.id;
      _printerMac = outcome.mac;
      _printerName = outcome.printerName;
      _error = null;
      _status = 'Siap mencetak ke ${outcome.printerName}.';
    });
  }

  Future<void> _doPrint() async {
    if (_headers.isEmpty || _currentIndex >= _headers.length) return;
    if (_printerMac == null) {
      setState(() => _error = 'Pilih printer terlebih dahulu.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _lastPrintSuccess = false;
      _status = 'Memulai proses cetak...';
    });

    final labelCode = _currentLabel;

    final ok = await _btService.printLabel(
      reportName: widget.reportName,
      query: {widget.labelQueryKey: labelCode},
      mac: _printerMac!,
      onStatus: (s) {
        if (mounted) setState(() => _status = s);
      },
      onError: (e) {
        if (mounted) setState(() => _error = e);
      },
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      // Log print ke microservice (fire-and-forget)
      final printBy = await DevicePrinterService.getLoggedUsername();
      DevicePrinterService.logPrint(
        printerId: _printerMac!,
        printBy: printBy,
      );
      setState(() {
        _lastPrintSuccess = true;
        _status = 'Label $labelCode berhasil dicetak.';
        _error = null;
      });

      // Tandai label sebagai sudah dicetak di backend
      widget.markAsPrinted?.call(labelCode);

      // Auto-advance ke label berikutnya
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      if (_hasNext) {
        setState(() {
          _currentIndex++;
          _lastPrintSuccess = false;
          _status = 'Siap untuk label berikutnya.';
        });
      }
    }
  }

  Future<void> _generateNewLabelSameData() async {
    if (!mounted) return;

    setState(() {
      _busy = true;
      _error = null;
      _lastPrintSuccess = false;
      _status = 'Membuat label baru (data sama)...';
    });

    try {
      final newHeaders = await widget.onGenerateSame();

      if (!mounted) return;

      if (newHeaders.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Gagal membuat label baru.';
          _status = 'Coba lagi.';
        });
        return;
      }

      setState(() {
        _headers.addAll(newHeaders);
        _count += newHeaders.length;
        _currentIndex = _headers.length - 1;
        _busy = false;
              _status = 'Label baru dibuat. Siap mencetak...';
      });

      await _doPrint();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Error: ${e.toString()}';
        _status = 'Terjadi kesalahan.';
      });
    }
  }
}
