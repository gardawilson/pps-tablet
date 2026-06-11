import 'package:flutter/material.dart';

/// Animated collapsible panel for riwayat produksi.
///
/// Expanded  — full width (40% of screen), shows [child] normally.
/// Collapsed — 44 px strip with icon + rotated label, click to re-open.
class RiwayatAnimatedPanel extends StatelessWidget {
  const RiwayatAnimatedPanel({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    this.expandedWidth,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  /// Full expanded content (Column with header + list).
  final Widget child;

  /// Explicit expanded width. Pass `constraints.maxWidth * 0.4` from a
  /// LayoutBuilder wrapping the parent Row so the sidebar is excluded.
  final double? expandedWidth;

  static const double _collapsedWidth = 44.0;
  static const Duration _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final expandedWidth = this.expandedWidth ?? MediaQuery.sizeOf(context).width * 0.4;
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeInOut,
      width: isExpanded ? expandedWidth : _collapsedWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ClipRect(
        child: isExpanded ? child : _CollapsedStrip(onTap: onToggle),
      ),
    );
  }
}

class _CollapsedStrip extends StatefulWidget {
  const _CollapsedStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CollapsedStrip> createState() => _CollapsedStripState();
}

class _CollapsedStripState extends State<_CollapsedStrip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hovered ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF);
    return Tooltip(
      message: 'Tampilkan Riwayat',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hovered
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF9FAFB),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(height: 12),
                Icon(Icons.history_rounded, size: 18, color: color),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'Riwayat Produksi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
