import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/utils/bt_print_service.dart';
import '../../core/utils/device_printer_service.dart';

class PrintOutcome {
  final String id; // microservice printer id
  final String mac;
  final String printerName;

  const PrintOutcome({
    required this.id,
    required this.mac,
    required this.printerName,
  });
}

class MasterPrinterSelector {
  const MasterPrinterSelector._();

  static Future<PrintOutcome?> show({
    required BuildContext context,
    String? currentMac,
  }) {
    return showDialog<PrintOutcome>(
      context: context,
      builder: (_) => _PrinterSelectionDialog(currentMac: currentMac),
    );
  }
}

// ── Dialog ─────────────────────────────────────────────────────────────────────

class _PrinterSelectionDialog extends StatefulWidget {
  final String? currentMac;

  const _PrinterSelectionDialog({this.currentMac});

  @override
  State<_PrinterSelectionDialog> createState() =>
      _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  bool _loading = true;
  // Printer dari microservice
  List<DevicePrinter> _registered = [];
  // Printer paired via BT tapi belum terdaftar
  List<BluetoothInfo> _paired = [];
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
      // Minta permission BT agar bisa lihat paired devices
      await BtPrintService.ensurePermissions();

      final results = await Future.wait([
        DevicePrinterService.fetchPrinters(),
        BtPrintService.getPairedDevices(),
      ]);

      if (!mounted) return;

      final registered = results[0] as List<DevicePrinter>;
      final paired = results[1] as List<BluetoothInfo>;

      // Pisahkan paired yang belum terdaftar di microservice
      final registeredMacs = registered
          .map((p) => p.identifier.toUpperCase())
          .toSet();
      final unregistered = paired
          .where((d) => !registeredMacs.contains(d.macAdress.toUpperCase()))
          .toList();

      setState(() {
        _registered = registered;
        _paired = unregistered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = 'Gagal mengambil daftar printer: $e';
      });
    }
  }

  Future<void> _register(BluetoothInfo device) async {
    // Tanya nama alias untuk printer baru
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _RegisterDialog(mac: device.macAdress, btName: device.name),
    );
    if (name == null || !mounted) return;

    try {
      final printer = await DevicePrinterService.registerPrinter(
        mac: device.macAdress,
        name: name,
      );
      if (!mounted) return;
      // Langsung pilih printer yang baru didaftarkan
      await _selectAndPop(printer);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftarkan printer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectAndPop(DevicePrinter printer) async {
    await DevicePrinterService.saveDefaultPrinter(printer);
    // Juga simpan ke BtPrintService agar kompatibel dengan alur print lama
    await BtPrintService.savePrinter(
      mac: printer.identifier,
      name: printer.name,
    );
    if (!mounted) return;
    Navigator.pop(
      context,
      PrintOutcome(
        id: printer.id,
        mac: printer.identifier,
        printerName: printer.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
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
                      Icons.print_rounded,
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
                          'Pilih Printer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Printer terdaftar di sistem',
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

            // ── Body ───────────────────────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Memuat daftar printer…',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_errorMsg != null)
              _buildError()
            else
              _buildList(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
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
              Icons.wifi_off_rounded,
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
    );
  }

  Widget _buildList() {
    final hasRegistered = _registered.isNotEmpty;
    final hasPaired = _paired.isNotEmpty;

    if (!hasRegistered && !hasPaired) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Text(
          'Tidak ada printer ditemukan.\nPair printer di Settings > Bluetooth Android terlebih dahulu.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Registered printers ─────────────────────────────────────
            if (hasRegistered) ...[
              _sectionHeader(
                'PRINTER TERDAFTAR',
                Icons.check_circle_outline_rounded,
                Colors.green.shade600,
              ),
              ...List.generate(_registered.length, (i) {
                return _RegisteredTile(
                  printer: _registered[i],
                  isSelected:
                      _registered[i].identifier.toUpperCase() ==
                      (widget.currentMac?.toUpperCase() ?? ''),
                  onTap: () => _selectAndPop(_registered[i]),
                );
              }),
            ],

            // ── Unregistered BT devices ─────────────────────────────────
            if (hasPaired) ...[
              _sectionHeader(
                'PERANGKAT BLUETOOTH (BELUM TERDAFTAR)',
                Icons.bluetooth_rounded,
                Colors.orange.shade600,
              ),
              ...List.generate(_paired.length, (i) {
                return _UnregisteredTile(
                  device: _paired[i],
                  onRegister: () => _register(_paired[i]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}

// ── Tile: registered printer ───────────────────────────────────────────────────

class _RegisteredTile extends StatelessWidget {
  final DevicePrinter printer;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegisteredTile({
    required this.printer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNormal = printer.status.toUpperCase() == 'NORMAL';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.print_rounded,
          size: 20,
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade500,
        ),
      ),
      title: Text(
        printer.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            printer.identifier,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: isNormal ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              printer.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isNormal ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.print_outlined, size: 11, color: Colors.grey.shade400),
          const SizedBox(width: 2),
          Text(
            printer.printUsage,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: Colors.blue.shade600)
          : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}

// ── Tile: unregistered BT device ──────────────────────────────────────────────

class _UnregisteredTile extends StatelessWidget {
  final BluetoothInfo device;
  final VoidCallback onRegister;

  const _UnregisteredTile({required this.device, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.bluetooth_rounded,
          size: 20,
          color: Colors.orange.shade600,
        ),
      ),
      title: Text(
        device.name.isNotEmpty ? device.name : device.macAdress,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        device.macAdress,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      trailing: TextButton(
        onPressed: onRegister,
        style: TextButton.styleFrom(
          backgroundColor: Colors.orange.shade50,
          foregroundColor: Colors.orange.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'DAFTAR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Register dialog ────────────────────────────────────────────────────────────

class _RegisterDialog extends StatefulWidget {
  final String mac;
  final String btName;

  const _RegisterDialog({required this.mac, required this.btName});

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  late final TextEditingController _controller;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      final empty = _controller.text.trim().isEmpty;
      if (empty != _isEmpty) setState(() => _isEmpty = empty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Batasi tinggi dialog agar tidak tertutup keyboard (landscape tablet safe)
    final availableHeight = mq.size.height - mq.viewInsets.bottom - 48;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: availableHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ───────────────────────────────────────────────
                const Text(
                  'Daftarkan Printer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),

                // ── Info MAC ─────────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.mac,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Petunjuk penamaan ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              height: 1.45,
                            ),
                            children: const [
                              TextSpan(
                                text:
                                    'Ketik nama sesuai label yang tertera di printer, contoh: ',
                              ),
                              TextSpan(
                                text: 'PANDA 1',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Input nama ───────────────────────────────────────────
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Nama printer',
                    hintText: 'mis. PANDA 1',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.label_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  onSubmitted: _isEmpty
                      ? null
                      : (_) => Navigator.pop(context, _controller.text.trim()),
                ),
                const SizedBox(height: 20),

                // ── Actions ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('BATAL'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isEmpty
                          ? null
                          : () =>
                                Navigator.pop(context, _controller.text.trim()),
                      child: const Text('DAFTAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
