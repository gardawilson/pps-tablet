import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/bt_print_service.dart';
import '../../core/utils/master_printer_repository.dart';

class PrintOutcome {
  final String mac;
  final String printerName;

  const PrintOutcome({
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
      builder: (_) => _PrinterSelectionDialog(
        currentMac: currentMac,
        repository: MasterPrinterRepository(api: ApiClient()),
      ),
    );
  }
}

class _PrinterSelectionDialog extends StatefulWidget {
  final String? currentMac;
  final MasterPrinterRepository repository;

  const _PrinterSelectionDialog({
    required this.currentMac,
    required this.repository,
  });

  @override
  State<_PrinterSelectionDialog> createState() =>
      _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  bool _loading = true;
  List<BluetoothInfo> _devices = [];
  Map<String, String> _aliases = {};
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
      final granted = await BtPrintService.ensurePermissions();
      if (!granted) {
        setState(() {
          _loading = false;
          _errorMsg =
              'Permission "Perangkat Terdekat" belum diizinkan.\nBuka Settings → PPS Tablet → Izin → Perangkat Terdekat.';
        });
        return;
      }

      final results = await Future.wait([
        BtPrintService.getPairedDevices(),
        widget.repository.fetchAliases(),
      ]);

      if (!mounted) return;

      setState(() {
        _devices = results[0] as List<BluetoothInfo>;
        _aliases = results[1] as Map<String, String>;
        _loading = false;
        if (_devices.isEmpty) {
          _errorMsg =
              'Tidak ada perangkat Bluetooth yang sudah di-pair. Pair printer di Settings > Bluetooth Android terlebih dahulu.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = 'Gagal mengambil daftar perangkat: $e';
      });
    }
  }

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
    if (!mounted) return;
    setState(() => _aliases = updated);
  }

  String _displayName(BluetoothInfo device) {
    return _aliases[device.macAdress] ??
        (device.name.isNotEmpty ? device.name : device.macAdress);
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
                    onPressed: _loading ? null : _loadDevices,
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
                      onPressed: _loadDevices,
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
                    final device = _devices[i];
                    final isSelected =
                        device.macAdress == widget.currentMac;
                    final displayName = _displayName(device);
                    final hasAlias = _aliases.containsKey(device.macAdress);
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
                        hasAlias && device.name.isNotEmpty
                            ? '${device.name} · ${device.macAdress}'
                            : device.macAdress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editAlias(device),
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
                            Icon(Icons.check_circle_rounded,
                                color: Colors.blue.shade600)
                          else
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.grey.shade300),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                        final mac = device.macAdress;
                        final name = displayName;
                        await BtPrintService.savePrinter(mac: mac, name: name);
                        if (!mounted) return;
                        Navigator.pop(
                          context,
                          PrintOutcome(mac: mac, printerName: name),
                        );
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
