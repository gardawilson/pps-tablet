import 'package:flutter/material.dart';

/// Floating drawer-style overlay for a collapsible sidebar section (e.g.
/// Riwayat Produksi / Stok Item) that sits on top of the main content
/// instead of pushing/squeezing it — so the mesin grid underneath always
/// keeps full width regardless of open/closed state.
class ProductionOverlayDrawer extends StatelessWidget {
  const ProductionOverlayDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.child,
    this.width,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final Widget child;
  final double? width;

  static const Duration _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final panelWidth = width ?? MediaQuery.sizeOf(context).width * 0.4;
    return IgnorePointer(
      ignoring: !isOpen,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: _duration,
              opacity: isOpen ? 1 : 0,
              child: GestureDetector(
                onTap: onClose,
                child: Container(color: Colors.black.withValues(alpha: 0.25)),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _duration,
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            right: isOpen ? 0 : -panelWidth,
            width: panelWidth,
            child: Material(
              elevation: 8,
              color: Colors.white,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small floating button that opens the [ProductionOverlayDrawer] when it's
/// closed — pinned to the edge of the screen so it doesn't overlap the
/// mesin grid content.
class ProductionOverlayDrawerToggle extends StatelessWidget {
  const ProductionOverlayDrawerToggle({
    super.key,
    required this.onPressed,
    this.icon = Icons.keyboard_double_arrow_left_rounded,
    this.tooltip = 'Tampilkan Sidebar',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: const Color(0xFF1D4ED8),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
