// =============================
// lib/common/widgets/qr_scanner_panel.dart
// Reusable QR/Barcode scanner panel using mobile_scanner
// - Cocok untuk tablet (default preview lebih tinggi)
// - Debounce & single-shot options to prevent double-detects
// - Torch & camera switch controls included
// - Simple rectangular overlay + corner guides
// - Support rotasi preview dalam kelipatan 90°
//
// Usage:
// QrScannerPanel(
//   onDetected: (value) { /* handle */ },
//   scanOnce: true,
//   debounceMs: 800,
//   rotationTurns: 1, // 90° ke kanan (default)
// )
// =============================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPanel extends StatefulWidget {
  /// Called when a code is detected. Respecting debounce & [scanOnce].
  final ValueChanged<String> onDetected;

  /// If true, will stop emitting after first successful detection
  /// until caller rebuilds/resets the widget.
  final bool scanOnce;

  /// Debounce window to ignore subsequent detections (ms).
  final int debounceMs;

  /// Optional explicit height of the camera preview.
  final double height;

  /// Optional: restrict formats if needed (null = all supported).
  final List<BarcodeFormat>? formats;

  /// Optional: show overlay guides.
  final bool showOverlay;

  /// Optional: border radius of preview container.
  final double borderRadius;

  /// Rotasi preview dalam kelipatan 90° (0..3)
  /// 0 = normal, 1 = 90° kanan, 2 = 180°, 3 = 270° (90° kiri)
  final int rotationTurns;

  const QrScannerPanel({
    super.key,
    required this.onDetected,
    this.scanOnce = true,
    this.debounceMs = 800,
    this.height = 260, // sedikit lebih tinggi, enak di tablet
    this.formats,
    this.showOverlay = true,
    this.borderRadius = 12,
    this.rotationTurns = 3, // default: putar 90° ke kanan
  });

  @override
  State<QrScannerPanel> createState() => _QrScannerPanelState();
}

class _QrScannerPanelState extends State<QrScannerPanel> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    torchEnabled: false,
  );

  bool _locked = false; // for debounce
  DateTime? _lastEmit;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_locked) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    // Debounce window
    final now = DateTime.now();
    if (_lastEmit != null) {
      final diff = now.difference(_lastEmit!).inMilliseconds;
      if (diff < widget.debounceMs) return;
    }

    _lastEmit = now;

    // Emit
    widget.onDetected(raw);

    // Optional single-shot lock
    if (widget.scanOnce) {
      _locked = true;
    } else {
      _locked = true;
      Future.delayed(Duration(milliseconds: widget.debounceMs), () {
        if (mounted) _locked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.borderRadius);

    // Pastikan nilai rotationTurns aman (0..3)
    final turns = widget.rotationTurns % 4;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: borderRadius,
        ),
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            // Camera preview dengan rotasi
            RotatedBox(
              quarterTurns: turns,
              child: MobileScanner(
                controller: _controller,
                onDetect: _handleDetection,
                // formats: widget.formats, // (Uncomment if you want to limit)
              ),
            ),

            // Optional overlay guides (tidak ikut di-rotate, tetap relatif ke panel)
            if (widget.showOverlay) _ScannerOverlay(),

            // Controls
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  _SquareIconButton(
                    icon: Icons.flip_camera_android,
                    tooltip: 'Ganti Kamera',
                    onPressed: () async {
                      await _controller.switchCamera();
                    },
                  ),
                  const SizedBox(width: 8),
                  _SquareIconButton(
                    icon: Icons.flash_on,
                    tooltip: 'Toggle Flash',
                    onPressed: () async {
                      await _controller.toggleTorch();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final boxW = w * 0.7;
        final boxH = h * 0.6;
        final left = (w - boxW) / 2;
        final top = (h - boxH) / 2;

        return Stack(
          children: [
            // Dim background with a hole
            Positioned.fill(
              child: CustomPaint(
                painter: _HolePainter(Rect.fromLTWH(left, top, boxW, boxH)),
              ),
            ),
            // Corner guides
            Positioned(
              left: left,
              top: top,
              child: _CornerGuide(width: boxW, height: boxH),
            ),
          ],
        );
      },
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect hole;
  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(12)));
    final path = Path.combine(PathOperation.difference, outer, inner);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) =>
      oldDelegate.hole != hole;
}

class _CornerGuide extends StatelessWidget {
  final double width;
  final double height;
  const _CornerGuide({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    const stroke = 3.0;
    const len = 20.0;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CornerPainter(strokeWidth: stroke, cornerLen: len),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double strokeWidth;
  final double cornerLen;

  _CornerPainter({required this.strokeWidth, required this.cornerLen});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // four corners
    // TL
    canvas.drawLine(Offset(0, 0), Offset(cornerLen, 0), p);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLen), p);
    // TR
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerLen, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), p);
    // BL
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), p);
    canvas.drawLine(Offset(0, size.height),
        Offset(0, size.height - cornerLen), p);
    // BR
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLen, size.height), p);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

// =============================
// Example usage in your screen:
// =============================

/*
// lib/features/production/broker/view/broker_inputs_screen.dart (snippet)
import 'package:pps_tablet/common/widgets/qr_scanner_panel.dart';

...

QrScannerPanel(
  onDetected: (code) {
    setState(() => _scannedCode = code);
  },
  scanOnce: true,
  debounceMs: 800,
  rotationTurns: 1, // 90° ke kanan
),
*/

