import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/qr_scanner_panel.dart';
import 'manual_label_input_dialog.dart';

/// Widget reusable untuk scan QR/barcode atau input manual
/// Hanya handle UI dan emit events ke parent
class SectionInputCard extends StatefulWidget {
  final String title;
  final String modeLabel;
  final List<DropdownMenuItem<String>> modeItems;
  final String selectedMode;
  final String manualHint;

  /// Callback ketika mode berubah
  final ValueChanged<String> onModeChanged;

  /// Callback ketika code berhasil di-scan atau di-input manual
  final ValueChanged<String> onCodeScanned;

  /// Optional: Disable semua input (saat processing)
  final bool isProcessing;

  /// Optional: Lock semua input (saat periode sudah ditutup)
  final bool isLocked;

  /// Optional: Tanggal terakhir periode ditutup
  final DateTime? lastClosedDate;

  const SectionInputCard({
    super.key,
    required this.title,
    required this.modeLabel,
    required this.modeItems,
    required this.selectedMode,
    required this.manualHint,
    required this.onModeChanged,
    required this.onCodeScanned,
    this.isProcessing = false,
    this.isLocked = false,
    this.lastClosedDate,
  });

  @override
  State<SectionInputCard> createState() => _SectionInputCardState();
}

class _SectionInputCardState extends State<SectionInputCard> {
  bool _scanActive = false;

  void _toggleScan() {
    if (widget.isProcessing || widget.isLocked) return;

    setState(() {
      _scanActive = !_scanActive;
    });
  }

  void _stopScan() {
    if (mounted) {
      setState(() {
        _scanActive = false;
      });
    }
  }

  /// Handle QR/Barcode detection dari scanner
  void _onScanDetected(String code) {
    if (widget.isLocked) return;
    _stopScan();
    widget.onCodeScanned(code);
  }

  /// Show dialog untuk input manual
  Future<void> _showManualInputDialog() async {
    if (widget.isLocked) return;

    // Stop scan dulu jika sedang aktif
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
      widget.onCodeScanned(result);
    }
  }

  /// Get caption text based on selected mode
  String _getModeCaption(String mode) {
    if (widget.isLocked) {
      return _getLockedCaption();
    }

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

  /// Get locked caption with formatted date
  String _getLockedCaption() {
    if (widget.lastClosedDate == null) {
      return 'Input tidak dapat dilakukan. Periode telah ditutup.';
    }

    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final date = widget.lastClosedDate!;
    final day = date.day;
    final month = months[date.month];
    final year = date.year;

    return 'Periode telah ditutup pada $day $month $year. Input tidak dapat dilakukan.';
  }

  /// Get color based on selected mode
  Color _getModeColor(BuildContext context) {
    if (widget.isLocked) {
      return Colors.grey.shade600;
    }

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

  /// Build placeholder when scanner is not active
  Widget _buildIdlePlaceholder() {
    if (widget.isLocked) {
      return _buildLockedPlaceholder();
    }

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
              'Tekan "Scan Kode" atau pilih "Ketik Manual"',
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

  /// Build locked placeholder
  Widget _buildLockedPlaceholder() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Input Terkunci',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Periode telah ditutup.\nInput tidak dapat dilakukan.',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _getModeColor(context);
    final bool disableControls = widget.isProcessing || widget.isLocked;

    return Card(
      elevation: _scanActive ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==================== HEADER ====================
          _buildHeader(disableControls),

          // ==================== BODY ====================
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Label + Badge
                  _buildModeSection(modeColor),

                  const SizedBox(height: 8),

                  // Mode Caption
                  Text(
                    _getModeCaption(widget.selectedMode),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isLocked
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                      fontWeight: widget.isLocked
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Mode Dropdown
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
                    onChanged: disableControls
                        ? null
                        : (val) {
                      if (val != null) widget.onModeChanged(val);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(disableControls),

                  const SizedBox(height: 14),

                  // Scanner or Placeholder
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _scanActive
                        ? _buildScannerSection()
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

  /// Build header section with gradient
  /// Build header section with gradient
  Widget _buildHeader(bool disableControls) {
    return Container(
      // ❌ HAPUS: width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isLocked
              ? [
            Colors.red.shade700,
            Colors.red.shade700.withOpacity(0.7),
          ]
              : [
            const Color(0xFF1565C0),
            const Color(0xFF1565C0).withOpacity(0.7),
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
            child: Icon(
              widget.isLocked ? Icons.lock : Icons.qr_code_scanner,
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
                  widget.isLocked
                      ? 'Terkunci • Periode telah ditutup.'
                      : _scanActive
                      ? 'Kamera aktif • Arahkan ke QR / barcode.'
                      : widget.isProcessing
                      ? 'Memproses...'
                      : 'Pilih mode, lalu scan atau ketik manual.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isProcessing)
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
    );
  }

  /// Build mode label with badge
  Widget _buildModeSection(Color modeColor) {
    return Row(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                widget.isLocked ? Icons.lock_outline : Icons.tune,
                size: 13,
                color: modeColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.isLocked
                    ? 'TERKUNCI'
                    : widget.selectedMode.toUpperCase(),
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
    );
  }

  /// Build action buttons (Scan & Manual)
  Widget _buildActionButtons(bool disableControls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;

        final scanButton = FilledButton.icon(
          onPressed: disableControls ? null : _toggleScan,
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
          onPressed: disableControls ? null : _showManualInputDialog,
          icon: const Icon(Icons.keyboard),
          label: const Text('Ketik Manual'),
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
    );
  }

  /// Build scanner section when active
  Widget _buildScannerSection() {
    return Column(
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
        ClipRRect(
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
              onDetected: _onScanDetected,
              scanOnce: true,
              debounceMs: 800,
              height: 220,
              showOverlay: true,
            ),
          ),
        ),
      ],
    );
  }
}