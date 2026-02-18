import 'package:flutter/material.dart';

class InteractivePopover {
  OverlayEntry? _entry;
  GlobalKey<_PopoverShellState>? _shellKey;

  Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required Widget child,
    EdgeInsets margin = const EdgeInsets.all(16),
    double maxWidth = 360,
    double maxHeight = 480,
    double dxOffset = 8,
    double dyOffset = 8,
    Duration duration = const Duration(milliseconds: 160),
    Curve curve = Curves.easeOutCubic,
    double startScale = 0.96,
    double startOpacity = 0.0,
    double backdropOpacity = 0.0,
    bool preferAbove = true,
    double verticalGap = 8,
  }) async {
    assert(startOpacity >= 0.0 && startOpacity <= 1.0);

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final screenSize = overlayBox.size;

    await hide();

    final leftFallback = (globalPosition.dx + dxOffset).clamp(
      margin.left,
      screenSize.width - margin.right - maxWidth,
    );
    final topFallback = (globalPosition.dy + dyOffset).clamp(
      margin.top,
      screenSize.height - margin.bottom - 120,
    );

    _shellKey = GlobalKey<_PopoverShellState>();
    _entry = OverlayEntry(
      builder: (_) => _PopoverShell(
        key: _shellKey,
        anchor: globalPosition,
        leftFallback: leftFallback.toDouble(),
        topFallback: topFallback.toDouble(),
        screenSize: screenSize,
        margin: margin,
        dxOffset: dxOffset,
        dyOffset: dyOffset,
        verticalGap: verticalGap,
        preferAbove: preferAbove,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        duration: duration,
        curve: curve,
        startScale: startScale,
        startOpacity: startOpacity,
        backdropOpacity: backdropOpacity.clamp(0.0, 1.0),
        onOutsideTap: hide,
        child: child,
      ),
    );

    overlay.insert(_entry!);
  }

  Future<void> hide() async {
    final state = _shellKey?.currentState;
    if (state != null && state.mounted) {
      await state.reverseAndWait();
    }
    _entry?.remove();
    _entry = null;
    _shellKey = null;
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
    _shellKey = null;
  }

  bool get isShown => _entry != null;
}

class _PopoverShell extends StatefulWidget {
  final Offset anchor;
  final double leftFallback;
  final double topFallback;
  final Size screenSize;
  final EdgeInsets margin;
  final double dxOffset;
  final double dyOffset;
  final double verticalGap;
  final bool preferAbove;
  final double maxWidth;
  final double maxHeight;
  final Duration duration;
  final Curve curve;
  final double startScale;
  final double startOpacity;
  final double backdropOpacity;
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
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _backdropOpacity;

  final _cardKey = GlobalKey();
  late bool _showAbove;
  late double _left;
  late double _top;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final scaleCurved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: Curves.easeInOutCubic,
    );
    final opacityCurved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    _scale = Tween<double>(begin: widget.startScale, end: 1).animate(
      scaleCurved,
    );
    _opacity = Tween<double>(begin: widget.startOpacity, end: 1).animate(
      opacityCurved,
    );
    _backdropOpacity = Tween<double>(begin: 0, end: widget.backdropOpacity)
        .animate(opacityCurved);

    _showAbove = widget.preferAbove;
    _left = widget.leftFallback;
    _top = widget.topFallback;

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndPosition());
    _controller.forward();
  }

  Future<void> reverseAndWait() async {
    if (!_controller.isAnimating) {
      try {
        await _controller.reverse();
      } catch (_) {}
    }
  }

  void _measureAndPosition() {
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final screen = widget.screenSize;
    final margin = widget.margin;

    final left = (widget.anchor.dx + widget.dxOffset).clamp(
      margin.left,
      screen.width - margin.right - size.width,
    );

    final spaceBelow =
        screen.height - widget.anchor.dy - widget.dyOffset - margin.bottom;
    final spaceAbove = widget.anchor.dy - margin.top;

    final placeAbove = widget.preferAbove
        ? size.height + widget.verticalGap <= spaceAbove ||
              spaceBelow < size.height
        : size.height > spaceBelow && spaceAbove >= size.height;

    final top = (placeAbove
            ? widget.anchor.dy - size.height - widget.verticalGap
            : widget.anchor.dy + widget.dyOffset)
        .clamp(margin.top, screen.height - margin.bottom - size.height);

    setState(() {
      _showAbove = placeAbove;
      _left = left.toDouble();
      _top = top.toDouble();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = _showAbove ? Alignment.bottomLeft : Alignment.topLeft;

    return Stack(
      children: [
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
        Positioned(
          left: _left,
          top: _top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value,
                alignment: alignment,
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
