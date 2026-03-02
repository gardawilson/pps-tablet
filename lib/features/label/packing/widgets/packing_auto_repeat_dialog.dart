import 'package:flutter/material.dart';

import '../../../../common/widgets/info_box.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/bt_print_service.dart';
import '../repository/packing_repository.dart';

/// Dialog auto-repeat: create → print → markAsPrinted, berulang sebanyak [totalRounds].
///
/// Round 1 menggunakan [firstNoBJ] yang sudah dibuat di form submit.
/// Round 2..N memanggil [onCreate] untuk membuat label baru lalu print.
class PackingAutoRepeatDialog extends StatefulWidget {
  final int totalRounds;
  final String firstNoBJ;
  final String reportName;
  final String baseUrl;

  /// Callback untuk membuat label baru (round 2+). Kembalikan NoBJ atau null jika gagal.
  final Future<String?> Function() onCreate;

  const PackingAutoRepeatDialog({
    super.key,
    required this.totalRounds,
    required this.firstNoBJ,
    required this.reportName,
    required this.baseUrl,
    required this.onCreate,
  });

  @override
  State<PackingAutoRepeatDialog> createState() =>
      _PackingAutoRepeatDialogState();
}

class _PackingAutoRepeatDialogState extends State<PackingAutoRepeatDialog> {
  // ── Printer ───────────────────────────────────────────────────────────────
  String? _printerMac;
  String? _printerName;
  late final BtPrintService _btService;

  // ── Progress ──────────────────────────────────────────────────────────────
  int _completedCount = 0;
  bool _running = false;
  bool _done = false;
  String _statusMsg = 'Pilih printer lalu tekan MULAI.';
  String? _errorMsg;

  /// Riwayat setiap round: NoBJ + apakah sukses
  final List<_RoundResult> _results = [];

  @override
  void initState() {
    super.initState();
    _btService = BtPrintService(baseUrl: widget.baseUrl, defaultSystem: 'pps');
    _loadSavedPrinter();
  }

  Future<void> _loadSavedPrinter() async {
    final saved = await BtPrintService.loadSavedPrinter();
    if (saved != null && mounted) {
      setState(() {
        _printerMac = saved.mac;
        _printerName = saved.name;
        _statusMsg = 'Printer: ${saved.name}. Tekan MULAI untuk memulai.';
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

      // ── Step 1: Tentukan NoBJ ─────────────────────────────────────────
      String? noBJ;
      if (round == 1) {
        // Label pertama sudah dibuat oleh form submit
        noBJ = widget.firstNoBJ;
      } else {
        _setStatus(round, total, 'Membuat label...');
        try {
          noBJ = await widget.onCreate();
        } catch (e) {
          _stopWithError(round, noBJ, 'Gagal membuat label: $e');
          return;
        }
        if (noBJ == null || noBJ.isEmpty) {
          _stopWithError(round, null, 'Create label gagal (tidak ada NoBJ).');
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
      _setStatus(round, total, 'Mencetak $noBJ...');
      bool printOk = false;
      String? printError;
      try {
        printOk = await _btService.printLabel(
          reportName: widget.reportName,
          query: {'NoBJ': noBJ},
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

      if (!printOk) {
        _stopWithError(round, noBJ, 'Cetak gagal: ${printError ?? "error"}');
        return;
      }

      // ── Step 3: Mark as printed ───────────────────────────────────────
      _setStatus(round, total, 'Menyimpan status cetak...');
      bool markOk = false;
      try {
        await PackingRepository(api: ApiClient()).markAsPrinted(noBJ);
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
            noBJ: noBJ!,
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

  void _stopWithError(int round, String? noBJ, String msg) {
    if (!mounted) return;
    setState(() {
      _running = false;
      _errorMsg = 'Round $round${noBJ != null ? " ($noBJ)" : ""}: $msg';
      if (noBJ != null) {
        _results.add(
          _RoundResult(round: round, noBJ: noBJ, success: false, marked: false),
        );
      }
    });
  }

  // ── Printer selector ───────────────────────────────────────────────────────

  Future<void> _selectPrinter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PrinterSheet(
        currentMac: _printerMac,
        onSelected: (mac, name) {
          setState(() {
            _printerMac = mac;
            _printerName = name;
            _errorMsg = null;
            _statusMsg = 'Printer: $name. Tekan MULAI untuk memulai.';
          });
        },
      ),
    );
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
                            r.noBJ,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasPrinter ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPrinter ? Colors.green.shade200 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth,
            size: 18,
            color: hasPrinter ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPrinter
                  ? (_printerName ?? _printerMac!)
                  : 'Belum ada printer dipilih',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasPrinter
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _running ? null : _selectPrinter,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              hasPrinter ? 'GANTI' : 'PILIH',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model ──────────────────────────────────────────────────────────────────────

class _RoundResult {
  final int round;
  final String noBJ;
  final bool success;
  final bool marked;

  const _RoundResult({
    required this.round,
    required this.noBJ,
    required this.success,
    required this.marked,
  });
}

// ── Printer Selector Sheet ─────────────────────────────────────────────────────

class _PrinterSheet extends StatefulWidget {
  final String? currentMac;
  final void Function(String mac, String name) onSelected;

  const _PrinterSheet({required this.currentMac, required this.onSelected});

  @override
  State<_PrinterSheet> createState() => _PrinterSheetState();
}

class _PrinterSheetState extends State<_PrinterSheet> {
  List<dynamic> _devices = [];
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
              'Permission "Perangkat Terdekat" belum diizinkan.\n'
              'Buka Settings → Aplikasi → PPS Tablet → Izin → aktifkan, lalu kembali.';
        });
        return;
      }
      final devices = await BtPrintService.getPairedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _loading = false;
          if (devices.isEmpty) {
            _errorMsg =
                'Tidak ada perangkat Bluetooth yang sudah di-pair.\n'
                'Pair printer di Settings > Bluetooth Android terlebih dahulu.';
          }
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _errorMsg = 'Error: $e';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.bluetooth_searching),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pilih Printer Bluetooth',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMsg!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    final mac = d.macAdress as String;
                    final name = (d.name as String).isNotEmpty
                        ? d.name as String
                        : '(Tanpa nama)';
                    final isSelected = mac == widget.currentMac;
                    return ListTile(
                      leading: Icon(
                        Icons.print,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade500,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        mac,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade700,
                            )
                          : null,
                      onTap: () async {
                        await BtPrintService.savePrinter(mac: mac, name: name);
                        if (!context.mounted) return;
                        widget.onSelected(mac, name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
