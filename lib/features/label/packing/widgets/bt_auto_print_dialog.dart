import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../../common/widgets/info_box.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/bt_print_service.dart';
import '../repository/packing_repository.dart';

typedef GenerateSameCallback = Future<List<dynamic>> Function();

class BtAutoPrintDialog extends StatefulWidget {
  final List<dynamic> headers;

  /// Total label berhasil dibuat (dari backend create)
  final int count;

  final String reportName;
  final String baseUrl;
  final GenerateSameCallback onGenerateSame;

  const BtAutoPrintDialog({
    super.key,
    required this.headers,
    required this.count,
    required this.reportName,
    required this.baseUrl,
    required this.onGenerateSame,
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
    final saved = await BtPrintService.loadSavedPrinter();
    if (saved != null && mounted) {
      setState(() {
        _printerMac = saved.mac;
        _printerName = saved.name;
        _status = 'Siap mencetak ke ${saved.name}.';
      });
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  String get _currentNoBJ {
    if (_headers.isEmpty || _currentIndex >= _headers.length) return '-';
    return _headers[_currentIndex]['NoBJ']?.toString() ?? '-';
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
                            _currentNoBJ,
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
                      tooltip: 'Copy NoBJ',
                      onPressed: (_currentNoBJ == '-' || _busy)
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(text: _currentNoBJ),
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Tersalin: $_currentNoBJ'),
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

  /// Row info printer terpilih + tombol GANTI
  Widget _buildPrinterRow() {
    final hasPrinter = _printerMac != null;
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
          const SizedBox(width: 6),
          TextButton(
            onPressed: _busy ? null : _selectPrinter,
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

  /// Buka bottom sheet untuk memilih printer Bluetooth
  Future<void> _selectPrinter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BtPrinterSelectorSheet(
        currentMac: _printerMac,
        onSelected: (mac, name) {
          setState(() {
            _printerMac = mac;
            _printerName = name;
            _error = null;
            _status = 'Siap mencetak ke $name.';
          });
        },
      ),
    );
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

    final noBJ = _currentNoBJ;

    final ok = await _btService.printLabel(
      reportName: widget.reportName,
      query: {'NoBJ': noBJ},
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
      setState(() {
        _lastPrintSuccess = true;
        _status = 'Label $noBJ berhasil dicetak.';
        _error = null;
      });

      // Tandai label sebagai sudah dicetak di backend
      PackingRepository(api: ApiClient()).markAsPrinted(noBJ).ignore();

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

// ── Printer Selector Bottom Sheet ─────────────────────────────────────────────

class _BtPrinterSelectorSheet extends StatefulWidget {
  final String? currentMac;
  final void Function(String mac, String name) onSelected;

  const _BtPrinterSelectorSheet({
    required this.currentMac,
    required this.onSelected,
  });

  @override
  State<_BtPrinterSelectorSheet> createState() =>
      _BtPrinterSelectorSheetState();
}

class _BtPrinterSelectorSheetState extends State<_BtPrinterSelectorSheet> {
  List<BluetoothInfo> _devices = [];
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // Cek permission dulu — jika ditolak, tampilkan pesan khusus
      final granted = await BtPrintService.ensurePermissions();
      if (!mounted) return;
      if (!granted) {
        setState(() {
          _loading = false;
          _errorMsg =
              'Permission "Perangkat Terdekat" (Nearby Devices) belum diizinkan.\n\n'
              'Buka Settings → Aplikasi → PPS Tablet → Izin → aktifkan Perangkat Terdekat, lalu kembali ke sini.';
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
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Gagal mengambil daftar perangkat: $e';
        });
      }
    }
  }

  Future<void> _selectDevice(BluetoothInfo device) async {
    final mac = device.macAdress;
    final name = device.name.isNotEmpty ? device.name : mac;

    // Simpan ke SharedPreferences
    await BtPrintService.savePrinter(mac: mac, name: name);

    if (!mounted) return;
    widget.onSelected(mac, name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header
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
                  onPressed: _loading ? null : _loadDevices,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'Menampilkan perangkat yang sudah di-pair di Bluetooth Android.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            const Divider(height: 20),

            // Content
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Mengambil daftar perangkat...'),
                    ],
                  ),
                ),
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
                      onPressed: _loadDevices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    final isSelected = d.macAdress == widget.currentMac;
                    return ListTile(
                      leading: Icon(
                        Icons.print,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade500,
                      ),
                      title: Text(
                        d.name.isNotEmpty ? d.name : '(Tanpa nama)',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        d.macAdress,
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
                      onTap: () => _selectDevice(d),
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
