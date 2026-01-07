import 'package:flutter/material.dart';

class InteractivePopover {
  OverlayEntry? _entry;
  GlobalKey<_PopoverShellState>? _shellKey;

  /// Tampilkan popover di sekitar [globalPosition] (koordinat global dari event long-press).
  Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required Widget child,
    EdgeInsets margin = const EdgeInsets.all(16),
    double maxWidth = 360,
    double maxHeight = 480,
    double dxOffset = 8,
    double dyOffset = 8,
    // Animasi
    Duration duration = const Duration(milliseconds: 160),
    Curve curve = Curves.easeOutCubic, // boleh overshoot untuk SCALE
    double startScale = 0.96,
    double startOpacity = 0.0,        // WAJIB 0..1
    double backdropOpacity = 0.0,     // 0–0.12 untuk bayangan tipis
    // Penempatan
    bool preferAbove = true,
    double verticalGap = 8,
  }) async {
    assert(startOpacity >= 0.0 && startOpacity <= 1.0, 'startOpacity harus 0..1');

    await hide(); // tutup yang lama (dengan reverse animasi jika ada)

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final screenSize = overlayBox.size;

    // Posisi fallback (sebelum kartu diukur), mulai dari bawah/kanan anchor
    final leftFallback = (globalPosition.dx + dxOffset)
        .clamp(margin.left, screenSize.width - margin.right - maxWidth);
    final topFallback = (globalPosition.dy + dyOffset)
        .clamp(margin.top, screenSize.height - margin.bottom - 120);

    _shellKey = GlobalKey<_PopoverShellState>();
    _entry = OverlayEntry(
      builder: (_) => _PopoverShell(
        key: _shellKey,
        // Data penempatan
        anchor: globalPosition,
        leftFallback: leftFallback.toDouble(),
        topFallback: topFallback.toDouble(),
        screenSize: screenSize,
        margin: margin,
        dxOffset: dxOffset,
        dyOffset: dyOffset,
        verticalGap: verticalGap,
        preferAbove: preferAbove,
        // Dimensi / animasi
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        duration: duration,
        curve: curve,
        startScale: startScale,
        startOpacity: startOpacity,
        backdropOpacity: backdropOpacity.clamp(0.0, 1.0),
        // Interaksi
        onOutsideTap: hide,
        child: child,
      ),
    );

    overlay.insert(_entry!);
  }

  /// Tutup dengan reverse animasi. Aman dipanggil berulang.
  Future<void> hide() async {
    final s = _shellKey?.currentState;
    if (s != null && s.mounted) {
      await s.reverseAndWait();
    }
    _entry?.remove();
    _entry = null;
    _shellKey = null;
  }

  /// Panggil di dispose() induk untuk bersih instan tanpa animasi.
  void dispose() {
    _entry?.remove();
    _entry = null;
    _shellKey = null;
  }

  bool get isShown => _entry != null;
}

class _PopoverShell extends StatefulWidget {
  // Anchor & fallback (sebelum tahu ukuran kartu)
  final Offset anchor;
  final double leftFallback;
  final double topFallback;

  // Lingkungan layar
  final Size screenSize;
  final EdgeInsets margin;
  final double dxOffset;
  final double dyOffset;
  final double verticalGap;
  final bool preferAbove;

  // Dimensi & animasi
  final double maxWidth;
  final double maxHeight;
  final Duration duration;
  final Curve curve; // dipakai untuk SCALE (boleh overshoot)
  final double startScale;
  final double startOpacity;
  final double backdropOpacity;

  // Interaksi
  final VoidCallback onOutsideTap;
  final Widget child;

  const _PopoverShell({
    super.key,
    required this.anchor,
    required this.leftFallback,
    required this.topFallback,
    required this.screenSize,
    required this.margin,
    required this.dxOffset,
    required this.dyOffset,
    required this.verticalGap,
    required this.preferAbove,
    required this.maxWidth,
    required this.maxHeight,
    required this.duration,
    required this.curve,
    required this.startScale,
    required this.startOpacity,
    required this.backdropOpacity,
    required this.onOutsideTap,
    required this.child,
  });

  @override
  State<_PopoverShell> createState() => _PopoverShellState();
}

class _PopoverShellState extends State<_PopoverShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _backdropOpacity;

  final _cardKey = GlobalKey();
  Size? _cardSize;
  late bool _showAbove;
  late double _left;
  late double _top;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: widget.duration);

    // SCALE boleh overshoot (mis. easeOutBack yang kamu kirim via widgets.curve)
    final scaleCurved = CurvedAnimation(
      parent: _ac,
      curve: widget.curve,
      reverseCurve: Curves.easeInOutCubic,
    );

    // OPACITY WAJIB non-overshoot (hindari nilai > 1)
    final opacityCurved = CurvedAnimation(
      parent: _ac,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    _scale   = Tween<double>(begin: widget.startScale,   end: 1).animate(scaleCurved);
    _opacity = Tween<double>(begin: widget.startOpacity, end: 1).animate(opacityCurved);

    _backdropOpacity = Tween<double>(begin: 0, end: widget.backdropOpacity)
        .animate(opacityCurved);

    // Posisi awal (fallback) sebelum pengukuran
    _showAbove = widget.preferAbove;
    _left = widget.leftFallback;
    _top = widget.topFallback;

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndPosition());
    _ac.forward();
  }

  Future<void> reverseAndWait() async {
    if (!_ac.isAnimating) {
      try {
        await _ac.reverse();
      } catch (_) {
        // bisa terjadi bila sudah unmounted — aman diabaikan
      }
    }
  }

  void _measureAndPosition() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    _cardSize = size;

    final screen = widget.screenSize;
    final margin = widget.margin;

    // Hitung posisi horizontal: mulai dari anchor.x lalu clamp ke layar
    double left = (widget.anchor.dx + widget.dxOffset)
        .clamp(margin.left, screen.width - margin.right - size.width);

    // Ketersediaan ruang
    final spaceBelow =
        screen.height - widget.anchor.dy - widget.dyOffset - margin.bottom;
    final spaceAbove = widget.anchor.dy - margin.top;

    // Tentukan di atas/bawah
    bool placeAbove;
    if (widget.preferAbove) {
      placeAbove = size.height + widget.verticalGap <= spaceAbove ||
          spaceBelow < size.height;
    } else {
      placeAbove = size.height > spaceBelow && spaceAbove >= size.height;
    }

    // Hitung top sesuai orientasi terpilih
    double top;
    if (placeAbove) {
      top = (widget.anchor.dy - size.height - widget.verticalGap)
          .clamp(margin.top, screen.height - margin.bottom - size.height);
    } else {
      top = (widget.anchor.dy + widget.dyOffset)
          .clamp(margin.top, screen.height - margin.bottom - size.height);
    }

    setState(() {
      _showAbove = placeAbove;
      _left = left.toDouble();
      _top = top.toDouble();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Origin animasi: jika muncul di atas, scale dari bawah-kiri (dekat anchor).
    final align = _showAbove ? Alignment.bottomLeft : Alignment.topLeft;

    return Stack(
      children: [
        // Backdrop (opsional)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onOutsideTap,
            child: AnimatedBuilder(
              animation: _backdropOpacity,
              builder: (_, __) => IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.black.withOpacity(
                    _backdropOpacity.value.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Kartu popover
        Positioned(
          left: _left,
          top: _top,
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, child) => Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0), // penting: 0..1
              child: Transform.scale(
                scale: _scale.value, // boleh overshoot
                alignment: align,
                child: child,
              ),
            ),
            child: Material(
              key: _cardKey,
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 220,
                  maxWidth: widget.maxWidth,
                  minHeight: 56,
                  maxHeight: widget.maxHeight,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
