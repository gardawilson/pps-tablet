import 'package:flutter/material.dart';

import '../../../../common/widgets/info_box.dart';
import '../../../../common/widgets/master_printer_selector.dart';
import '../../../../common/widgets/printer_selector_tile.dart';
import '../../../../core/utils/bt_print_service.dart';
import '../../../../core/utils/device_printer_service.dart';
import '../repository/furniture_wip_repository.dart';

/// Dialog auto-repeat: create → print → markAsPrinted, berulang sebanyak [totalRounds].
///
/// Round 1 menggunakan [firstNoLabel] yang sudah dibuat di form submit.
/// Round 2..N memanggil [onCreate] untuk membuat label baru lalu print.
class FurnitureWipAutoRepeatDialog extends StatefulWidget {
  final int totalRounds;
  final String firstNoLabel;
  final String reportName;
  final String baseUrl;

/// Callback untuk membuat label baru (round 2+). Kembalikan NoFurnitureWIP atau null jika gagal.
  final Future<String?> Function() onCreate;

  const FurnitureWipAutoRepeatDialog({
    super.key,
    required this.totalRounds,
    required this.firstNoLabel,
    required this.reportName,
    required this.baseUrl,
    required this.onCreate,
  });

  @override
  State<FurnitureWipAutoRepeatDialog> createState() =>
      _FurnitureWipAutoRepeatDialogState();
}

class _FurnitureWipAutoRepeatDialogState
    extends State<FurnitureWipAutoRepeatDialog> {
  // ── Printer ───────────────────────────────────────────────────────────────
  String? _printerId;
  String? _printerMac;
  String? _printerName;
  late final BtPrintService _btService;

  // ── Progress ──────────────────────────────────────────────────────────────
  int _completedCount = 0;
  bool _running = false;
  bool _done = false;
  String _statusMsg = 'Pilih printer lalu tekan MULAI.';
  String? _errorMsg;

  /// Riwayat setiap round: NoFurnitureWIP + apakah sukses
  final List<_RoundResult> _results = [];

  @override
  void initState() {
    super.initState();
    _btService = BtPrintService(baseUrl: widget.baseUrl, defaultSystem: 'pps');
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final saved = await DevicePrinterService.loadDefaultPrinter();
    if (saved != null && mounted) {
      setState(() {
        _printerId = saved.id;
        _printerMac = saved.mac;
        _printerName = saved.name;
        _statusMsg = 'Printer: ${saved.name}. Tekan MULAI untuk memulai.';
      });
      return;
    }
    final legacy = await BtPrintService.loadSavedPrinter();
    if (legacy != null && mounted) {
      setState(() {
        _printerMac = legacy.mac;
        _printerName = legacy.name;
        _statusMsg = 'Printer: ${legacy.name}. Tekan MULAI untuk memulai.';
      });
    }
  }

  // ── Loop utama ─────────────────────────────────────────────────────────────

  Future<void> _startLoop() async {
    if (_printerMac == null) {
      setState(() => _errorMsg = 'Pilih printer terlebih dahulu.');
      return;
    }

    setState(() {
      _running = true;
      _errorMsg = null;
    });

    final int total = widget.totalRounds;

    for (int round = _completedCount + 1; round <= total; round++) {
      if (!mounted) return;

      setState(() {
        _errorMsg = null;
        _statusMsg = 'Round $round/$total — Menyiapkan...';
      });

      // ── Step 1: Tentukan label Furniture WIP ────────────────────────────
      String? labelCode;
      if (round == 1) {
        // Label pertama sudah dibuat oleh form submit
        labelCode = widget.firstNoLabel;
      } else {
        _setStatus(round, total, 'Membuat label...');
        try {
          labelCode = await widget.onCreate();
        } catch (e) {
          _stopWithError(round, labelCode, 'Gagal membuat label: $e');
          return;
        }
        if (labelCode == null || labelCode.isEmpty) {
          _stopWithError(
            round,
            null,
            'Create label gagal (tidak ada NoFurnitureWIP).',
          );
          return;
        }

        // Tunggu sebentar agar data label tersedia di Crystal Reports server.
        // Label baru saja di-INSERT ke DB; tanpa jeda, server kadang return 500
        // karena Crystal Reports query belum bisa menemukan row yang baru.
        _setStatus(round, total, 'Menunggu server...');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
      }

      // ── Step 2: Print ─────────────────────────────────────────────────
      _setStatus(round, total, 'Mencetak $labelCode...');
      bool printOk = false;
      String? printError;
      try {
        printOk = await _btService.printLabel(
          reportName: widget.reportName,
          query: {'NoFurnitureWIP': labelCode},
          mac: _printerMac!,
          onStatus: (s) {
            if (mounted)
              setState(() => _statusMsg = 'Round $round/$total — $s');
          },
          onError: (e) => printError = e,
        );
      } catch (e) {
        printOk = false;
        printError = e.toString();
      }

      if (printOk) {
        final printBy = await DevicePrinterService.getLoggedUsername();
        DevicePrinterService.logPrint(printerId: _printerMac!, printBy: printBy);
      }

      if (!printOk) {
        _stopWithError(round, labelCode, 'Cetak gagal: ${printError ?? "error"}');
        return;
      }

      // ── Step 3: Mark as printed ───────────────────────────────────────
      _setStatus(round, total, 'Menyimpan status cetak...');
      bool markOk = false;
      try {
        await FurnitureWipRepository().markAsPrinted(labelCode!);
        markOk = true;
      } catch (_) {
        // markAsPrinted failure non-fatal — print sudah terjadi secara fisik
        markOk = false;
      }

      if (!mounted) return;

      // ── Round selesai ─────────────────────────────────────────────────
      setState(() {
        _completedCount++;
        _results.add(
          _RoundResult(
            round: round,
            noLabel: labelCode!,
            success: true,
            marked: markOk,
          ),
        );
        _statusMsg = '$_completedCount/$total selesai.';
      });

      // Jeda singkat antar round agar socket BT bersih
      if (round < total) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    if (mounted) {
      setState(() {
        _running = false;
        _done = true;
        _statusMsg =
            '✅ Semua $_completedCount/$total label berhasil dibuat dan dicetak!';
      });
    }
  }

  void _setStatus(int round, int total, String msg) {
    if (mounted) setState(() => _statusMsg = 'Round $round/$total — $msg');
  }

  void _stopWithError(int round, String? noLabel, String msg) {
    if (!mounted) return;
    setState(() {
      _running = false;
      _errorMsg = 'Round $round${noLabel != null ? " ($noLabel)" : ""}: $msg';
      if (noLabel != null) {
        _results.add(
          _RoundResult(
            round: round,
            noLabel: noLabel,
            success: false,
            marked: false,
          ),
        );
      }
    });
  }

  // ── Printer selector ───────────────────────────────────────────────────────

  Future<void> _selectPrinter() async {
    final outcome = await MasterPrinterSelector.show(
      context: context,
      currentMac: _printerMac,
    );
    if (outcome == null || !mounted) return;
    setState(() {
      _printerId = outcome.id;
      _printerMac = outcome.mac;
      _printerName = outcome.printerName;
      _errorMsg = null;
      _statusMsg = 'Printer: ${outcome.printerName}. Tekan MULAI untuk memulai.';
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasPrinter = _printerMac != null;
    final canStart = !_running && !_done && hasPrinter;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ──
              Row(
                children: [
                  Icon(Icons.loop, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Auto Create & Print  ($_completedCount / ${widget.totalRounds})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (!_running)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Tutup',
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.totalRounds > 0
                      ? _completedCount / widget.totalRounds
                      : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: _done ? Colors.green : Colors.blue.shade600,
                ),
              ),

              const SizedBox(height: 10),

              // ── Printer row ──
              _buildPrinterRow(hasPrinter),

              const SizedBox(height: 10),

              // ── Status box ──
              InfoBox(
                height: 72,
                busy: _running,
                isError: _errorMsg != null,
                icon: _errorMsg != null
                    ? Icons.error_outline
                    : (_done ? Icons.check_circle_outline : Icons.info_outline),
                iconColor: _errorMsg != null
                    ? Colors.red.shade700
                    : (_done ? Colors.green.shade700 : Colors.blue.shade700),
                text: _errorMsg ?? _statusMsg,
              ),

              const SizedBox(height: 10),

              // ── Log hasil ──
              if (_results.isNotEmpty) ...[
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final r = _results[_results.length - 1 - i];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            r.success ? Icons.check_circle : Icons.cancel,
                            color: r.success
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                            size: 20,
                          ),
                          title: Text(
                            r.noLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Text(
                            r.success
                                ? (r.marked
                                      ? '✓ Tercetak'
                                      : '✓ Print (mark gagal)')
                                : '✗ Gagal',
                            style: TextStyle(
                              fontSize: 11,
                              color: r.success
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── Actions ──
              if (!_done)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canStart ? _startLoop : null,
                    icon: _running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _running
                          ? 'Sedang berjalan...'
                          : (_completedCount > 0 ? 'LANJUTKAN' : 'MULAI'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SELESAI',
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

  Widget _buildPrinterRow(bool hasPrinter) {
    return PrinterSelectorTile(
      printerName: _printerName,
      printerMac: _printerMac,
      printerId: _printerId,
      onSelect: _selectPrinter,
      disabled: _running,
      compact: true,
    );
  }
}

// ── Model ──────────────────────────────────────────────────────────────────────

class _RoundResult {
  final int round;
  final String noLabel;
  final bool success;
  final bool marked;

  const _RoundResult({
    required this.round,
    required this.noLabel,
    required this.success,
    required this.marked,
  });
}

