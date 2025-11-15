import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pps_tablet/common/widgets/qr_scanner_panel.dart';

import '../../broker/view_model/broker_production_input_view_model.dart';
import '../../broker/widgets/lookup_label_dialog.dart';
import '../../broker/widgets/lookup_label_partial_dialog.dart';
import 'manual_label_input_dialog.dart';


class ScanManualCard extends StatefulWidget {
  final String title;
  final String modeLabel;
  final List<DropdownMenuItem<String>> modeItems;
  final String selectedMode;
  final String manualHint;
  final String noProduksi;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String?> onCodeChanged;

  // ✅ NEW: Callback untuk snackbar (agar tidak error saat widget unmounted)
  final Function(String message, {bool isSuccess})? onShowMessage;

  const ScanManualCard({
    super.key,
    required this.title,
    required this.modeLabel,
    required this.modeItems,
    required this.selectedMode,
    required this.manualHint,
    required this.noProduksi,
    required this.onModeChanged,
    required this.onCodeChanged,
    this.onShowMessage,
  });

  @override
  State<ScanManualCard> createState() => _ScanManualCardState();
}

class _ScanManualCardState extends State<ScanManualCard> {
  bool _scanActive = false;
  bool _isProcessing = false;

  void _stopScan() {
    if (mounted) {
      setState(() {
        _scanActive = false;
      });
    }
  }

  void _toggleScan() {
    if (mounted) {
      setState(() {
        _scanActive = !_scanActive;
      });
    }
  }

  /// Handle kode yang di-scan atau input manual
  Future<void> _handleCodeInput(String code) async {
    if (_isProcessing) return;

    if (mounted) {
      setState(() => _isProcessing = true);
    }

    try {
      final vm = context.read<BrokerProductionInputViewModel>();

      // Lookup data berdasarkan code
      await vm.lookupLabel(code);

      if (!mounted) return;

      final result = vm.lastLookup;
      if (result == null || result.data.isEmpty) {
        _showMessage('Label tidak ditemukan atau tidak memiliki data', isSuccess: false);
        return;
      }

      // Route berdasarkan mode
      switch (widget.selectedMode.toLowerCase()) {
        case 'full':
          await _handleFullMode(vm, code);
          break;
        case 'select':
          await _handleSelectMode();
          break;
        case 'partial':
          await _handlePartialMode();
          break;
        default:
          _showMessage('Mode tidak dikenali', isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Terjadi kesalahan: $e', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Mode FULL: Auto-select semua item dan commit langsung (tanpa dialog)
  Future<void> _handleFullMode(BrokerProductionInputViewModel vm, String code) async {
    final result = vm.lastLookup;
    if (result == null) return;

    // Clear picks terlebih dahulu
    vm.clearPicks();

    // Select semua item yang bukan duplikat
    int selectedCount = 0;
    for (int i = 0; i < result.data.length; i++) {
      final row = result.data[i];

      // Skip jika duplikat
      if (vm.willBeDuplicate(row, widget.noProduksi)) {
        continue;
      }

      // Pick item
      if (!vm.isPicked(row)) {
        vm.togglePick(row);
        selectedCount++;
      }
    }

    // Commit langsung
    if (selectedCount > 0) {
      final commitResult = vm.commitPickedToTemp(noProduksi: widget.noProduksi);

      // ✅ Update parent dulu sebelum show snackbar
      widget.onCodeChanged(code);

      // ✅ Tunggu sebentar untuk ensure widget masih mounted
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final msg = commitResult.added > 0
          ? '✓ Ditambahkan ${commitResult.added} item dari label $code${commitResult.skipped > 0 ? ' • ${commitResult.skipped} duplikat terlewati' : ''}'
          : 'Semua item sudah ada (duplikat)';

      _showMessage(msg, isSuccess: commitResult.added > 0);
    } else {
      _showMessage('Tidak ada item baru yang bisa ditambahkan (semua duplikat)', isSuccess: false);
    }
  }

  /// Mode SELECT: Tampilkan dialog untuk pilih item (sebagian pallet)
  Future<void> _handleSelectMode() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LookupLabelDialog(
        noProduksi: widget.noProduksi,
        selectedMode: widget.selectedMode,
      ),
    );
  }

  /// Mode PARTIAL: Tampilkan dialog partial
  Future<void> _handlePartialMode() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LookupLabelPartialDialog(
        noProduksi: widget.noProduksi,
        selectedMode: widget.selectedMode,
      ),
    );
  }

  Future<void> _showManualInputDialog() async {
    if (_scanActive) {
      _stopScan();
    }

    if (!mounted) return;

    final result = await ManualLabelInputDialog.show(
      context: context,
      title: 'Input Manual',
      labelText: 'Kode label',
      hintText: widget.manualHint,
      initialValue: null,
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      await _handleCodeInput(result);
    }
  }

  // ✅ NEW: Safe message handler
  void _showMessage(String message, {bool isSuccess = true}) {
    // Prioritas: gunakan callback parent jika ada
    if (widget.onShowMessage != null) {
      widget.onShowMessage!(message, isSuccess: isSuccess);
      return;
    }

    // Fallback: coba tampilkan snackbar jika widget masih mounted
    if (!mounted) return;

    // ✅ Gunakan post frame callback untuk ensure UI sudah stabil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        // Silently fail jika context sudah tidak valid
        debugPrint('Failed to show snackbar: $e');
      }
    });
  }

  String _modeCaption(String mode) {
    switch (mode.toLowerCase()) {
      case 'full':
        return 'Scan dan langsung gunakan seluruh isi tanpa konfirmasi.';
      case 'select':
        return 'Scan, lalu pilih item mana saja yang akan dipakai.';
      case 'partial':
        return 'Scan, pilih item dan ubah beratnya untuk membuat partial.';
      default:
        return 'Atur cara penggunaan label melalui mode ini.';
    }
  }

  Color _modeColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget.selectedMode.toLowerCase()) {
      case 'full':
        return Colors.green.shade600;
      case 'select':
        return theme.colorScheme.primary;
      case 'partial':
        return Colors.orange.shade700;
      default:
        return theme.colorScheme.secondary;
    }
  }

  Widget _buildIdlePlaceholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Kamera belum dinyalakan',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan "Scan Kode" atau pilih "Input Manual"',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeColor = _modeColor(context);

    final bool disableScan = _isProcessing;
    final bool disableManual = _scanActive || _isProcessing;

    return Card(
      elevation: _scanActive ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER DENGAN GRADIENT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    size: 20,
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
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _scanActive
                            ? 'Kamera aktif • Arahkan ke QR / barcode.'
                            : _isProcessing
                            ? 'Memproses...'
                            : 'Pilih mode, lalu scan atau input manual.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // BODY
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // MODE + CAPTION
                  Row(
                    children: [
                      Text(
                        widget.modeLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: modeColor.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: modeColor.withOpacity(0.5),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 13,
                              color: modeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.selectedMode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: modeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modeCaption(widget.selectedMode),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: widget.selectedMode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    items: widget.modeItems,
                    onChanged: _isProcessing
                        ? null
                        : (val) {
                      if (val != null) widget.onModeChanged(val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // BUTTONS: SCAN & MANUAL
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 480;

                      final scanButton = FilledButton.icon(
                        onPressed: disableScan ? null : _toggleScan,
                        icon: Icon(
                          _scanActive ? Icons.close : Icons.center_focus_strong,
                        ),
                        label: Text(_scanActive ? 'Tutup Kamera' : 'Scan Kode'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );

                      final manualButton = OutlinedButton.icon(
                        onPressed: disableManual ? null : _showManualInputDialog,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Input Manual'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );

                      return isWide
                          ? Row(
                        children: [
                          Expanded(child: scanButton),
                          const SizedBox(width: 10),
                          Expanded(child: manualButton),
                        ],
                      )
                          : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: scanButton,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: manualButton,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // SCANNER / IDLE PLACEHOLDER
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _scanActive
                        ? Column(
                      key: const ValueKey('scanner'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Scan QR / Barcode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenHeight = MediaQuery.of(context).size.height;
                            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                            final availableHeight = screenHeight - keyboardHeight - 450;
                            final scannerHeight = availableHeight.clamp(180.0, 280.0);

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: QrScannerPanel(
                                  onDetected: (code) async {
                                    if (mounted) {
                                      setState(() => _scanActive = false);
                                    }
                                    await _handleCodeInput(code);
                                  },
                                  scanOnce: true,
                                  debounceMs: 800,
                                  height: 220,
                                  showOverlay: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                        : _buildIdlePlaceholder(),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}