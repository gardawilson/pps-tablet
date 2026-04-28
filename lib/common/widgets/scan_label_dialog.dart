import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

/// A reusable scan / manual-input label dialog.
///
/// [onLookup] is called with the scanned or typed code.
/// Return `null` on success (dialog closes automatically), or an error string
/// to show to the user.
///
/// When [acceptedLabels] is non-empty, the dialog renders a two-column layout:
/// left panel lists accepted label types, right panel has scan/manual tabs.
///
/// [headerSubtitle] renders a plain text subtitle in the header, e.g. category
/// name for Bongkar Susun.
class ScanLabelDialog extends StatefulWidget {
  final Future<String?> Function(String code) onLookup;
  final String manualHint;
  final String? headerSubtitle;
  final List<({String prefix, String label})> acceptedLabels;

  const ScanLabelDialog({
    super.key,
    required this.onLookup,
    required this.manualHint,
    this.headerSubtitle,
    this.acceptedLabels = const [],
  });

  @override
  State<ScanLabelDialog> createState() => _ScanLabelDialogState();
}

class _ScanLabelDialogState extends State<ScanLabelDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabCtl;

  final TextEditingController _ctl = TextEditingController();
  final FocusNode _focus = FocusNode();
  final MobileScannerController _scannerCtl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  Color? _flashColor;
  String? _scanError;
  String? _lookupError;
  bool _isProcessingScan = false;
  bool _isLookingUp = false;
  int _cameraQuarterTurns = 3;

  bool get _hasSidePanel => widget.acceptedLabels.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabCtl = TabController(length: 2, vsync: this);
    _tabCtl.addListener(() {
      if (_tabCtl.indexIsChanging) return;
      setState(() {});
      if (_tabCtl.index == 0) {
        _scannerCtl.start();
      } else {
        _scannerCtl.stop();
        _focus.requestFocus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRotation());
  }

  @override
  void didChangeMetrics() => _updateRotation();

  void _updateRotation() {
    if (!mounted) return;
    final size = View.of(context).physicalSize;
    if (size.height > size.width && _cameraQuarterTurns != 0) {
      setState(() => _cameraQuarterTurns = 0);
      if (_tabCtl.index == 0) {
        _scannerCtl.stop();
        _scannerCtl.start();
      }
    }
  }

  void _toggleCameraRotation() {
    setState(() => _cameraQuarterTurns = _cameraQuarterTurns == 1 ? 3 : 1);
    if (_tabCtl.index == 0) {
      _scannerCtl.stop();
      _scannerCtl.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtl.dispose();
    _ctl.dispose();
    _focus.dispose();
    _scannerCtl.dispose();
    super.dispose();
  }

  Future<void> _addManual() async {
    final code = _ctl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isLookingUp = true;
      _lookupError = null;
    });
    final error = await widget.onLookup(code);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLookingUp = false;
        _lookupError = error;
      });
    }
  }

  Future<void> _onScanDetect(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessingScan = true;
      _scanError = null;
    });

    final error = await widget.onLookup(code);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _flashColor = Colors.red;
        _scanError = error;
        _isProcessingScan = false;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _flashColor = null;
          _scanError = null;
        });
      }
    }
  }

  double _keyboardInset = 0;

  @override
  Widget build(BuildContext context) {
    _keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _hasSidePanel ? 640 : 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasSidePanel) _buildSidePanel(),
                    Expanded(child: _buildMainPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Blue header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Scan / Input Label',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (widget.headerSubtitle != null) ...[
            Text(
              widget.headerSubtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left panel: accepted label types ──────────────────────────────────────

  Widget _buildSidePanel() {
    return Container(
      width: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        border: Border(right: BorderSide(color: _kBorder)),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label_outline_rounded,
                size: 13,
                color: _kPrimary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                'Label diterima',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...widget.acceptedLabels.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      e.prefix,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      e.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A5568),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Right panel: TabBar + camera/manual content ────────────────────────────

  Widget _buildMainPanel() {
    final borderRadius = _hasSidePanel
        ? const BorderRadius.only(bottomRight: Radius.circular(16))
        : const BorderRadius.vertical(bottom: Radius.circular(16));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab bar strip
          Container(
            color: _kPrimary,
            child: TabBar(
              controller: _tabCtl,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.camera_alt_outlined, size: 18),
                  text: 'Scan Kamera',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.keyboard_outlined, size: 18),
                  text: 'Input Manual',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
          // Tab content
          SizedBox(
            height: 400,
            child: IndexedStack(
              index: _tabCtl.index,
              children: [_buildCameraTab(), _buildManualTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera tab ─────────────────────────────────────────────────────────────

  Widget _buildCameraTab() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: _hasSidePanel
                  ? Radius.zero
                  : const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            child: RotatedBox(
              quarterTurns: _cameraQuarterTurns,
              child: MobileScanner(
                controller: _scannerCtl,
                onDetect: _onScanDetect,
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _ScanFramePainter())),
        Positioned.fill(
          child: Center(
            child: Lottie.asset(
              'assets/animations/scanner.json',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (_flashColor != null)
          Positioned.fill(
            child: ColoredBox(color: _flashColor!.withValues(alpha: 0.2)),
          ),
        if (_isProcessingScan)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55000000),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        if (_scanError != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _scanError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _toggleCameraRotation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.screen_rotation_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Manual tab ─────────────────────────────────────────────────────────────

  Widget _buildManualTab() {
    return SingleChildScrollView(
      reverse: true,
      padding: EdgeInsets.fromLTRB(20, 20, 20, _keyboardInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctl,
            focusNode: _focus,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Kode Label',
              hintText: widget.manualHint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              errorText: _lookupError,
              errorStyle: const TextStyle(fontSize: 11),
              errorMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              filled: true,
              fillColor: _kSurface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: _ctl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => setState(() => _ctl.clear()),
                    )
                  : null,
            ),
            onSubmitted: (_) => _addManual(),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: Material(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _isLookingUp ? null : _addManual,
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: _isLookingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tambah Label',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan frame painter (symmetric, explicit per-corner arcs) ────────────────

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 28.0;
    const r = 9.0; // corner radius
    const strokeW = 3.5;

    final boxSize = size.shortestSide * 0.65;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - boxSize / 2;
    final top = cy - boxSize / 2;
    final right = cx + boxSize / 2;
    final bottom = cy + boxSize / 2;

    // Dim overlay with rounded hole
    final dimPaint = Paint()..color = const Color(0x66000000);
    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          const Radius.circular(r + 2),
        ),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, dimPaint);

    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left: arc from 180° → 270° at rect (left, top, 2r, 2r)
    canvas.drawArc(
      Rect.fromLTWH(left, top, r * 2, r * 2),
      math.pi,
      math.pi / 2,
      false,
      p,
    );
    canvas.drawLine(
      Offset(left + r, top),
      Offset(left + r + cornerLen, top),
      p,
    );
    canvas.drawLine(
      Offset(left, top + r),
      Offset(left, top + r + cornerLen),
      p,
    );

    // Top-right: arc from 270° → 360° at rect (right-2r, top, 2r, 2r)
    canvas.drawArc(
      Rect.fromLTWH(right - r * 2, top, r * 2, r * 2),
      3 * math.pi / 2,
      math.pi / 2,
      false,
      p,
    );
    canvas.drawLine(
      Offset(right - r, top),
      Offset(right - r - cornerLen, top),
      p,
    );
    canvas.drawLine(
      Offset(right, top + r),
      Offset(right, top + r + cornerLen),
      p,
    );

    // Bottom-left: arc from 90° → 180° at rect (left, bottom-2r, 2r, 2r)
    canvas.drawArc(
      Rect.fromLTWH(left, bottom - r * 2, r * 2, r * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      p,
    );
    canvas.drawLine(
      Offset(left, bottom - r),
      Offset(left, bottom - r - cornerLen),
      p,
    );
    canvas.drawLine(
      Offset(left + r, bottom),
      Offset(left + r + cornerLen, bottom),
      p,
    );

    // Bottom-right: arc from 0° → 90° at rect (right-2r, bottom-2r, 2r, 2r)
    canvas.drawArc(
      Rect.fromLTWH(right - r * 2, bottom - r * 2, r * 2, r * 2),
      0,
      math.pi / 2,
      false,
      p,
    );
    canvas.drawLine(
      Offset(right, bottom - r),
      Offset(right, bottom - r - cornerLen),
      p,
    );
    canvas.drawLine(
      Offset(right - r, bottom),
      Offset(right - r - cornerLen, bottom),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
