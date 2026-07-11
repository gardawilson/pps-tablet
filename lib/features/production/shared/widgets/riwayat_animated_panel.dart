import 'package:flutter/material.dart';

import 'sidebar_tab_switcher.dart';

/// Animated collapsible panel for riwayat produksi.
///
/// Expanded  — full width (40% of screen), shows [child] normally.
/// Collapsed — 44 px strip. If [railTabs] is provided (Gmail-style), it
/// shows a stacked icon rail — one icon per tab plus an expand arrow — so
/// it stays clear that multiple sections live inside the panel even while
/// collapsed. Otherwise falls back to a single icon + rotated label.
class RiwayatAnimatedPanel extends StatelessWidget {
  const RiwayatAnimatedPanel({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    this.expandedWidth,
    this.collapsedLabel = 'Riwayat Produksi',
    this.collapsedIcon = Icons.history_rounded,
    this.collapsedTooltip = 'Tampilkan Riwayat',
    this.showLeftBorder = true,
    this.railTabs,
    this.selectedTabIndex,
    this.onTabSelected,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  /// Full expanded content (Column with header + list).
  final Widget child;

  /// Explicit expanded width. Pass `constraints.maxWidth * 0.4` from a
  /// LayoutBuilder wrapping the parent Row so the sidebar is excluded.
  final double? expandedWidth;

  /// Label & icon shown on the collapsed strip when [railTabs] is not
  /// given — customize when reusing this panel for a single-section
  /// sidebar (e.g. Stok Item).
  final String collapsedLabel;
  final IconData collapsedIcon;
  final String collapsedTooltip;

  /// Set false when this panel sits to the right of another animated
  /// panel so a double border doesn't appear between them.
  final bool showLeftBorder;

  /// When set, the collapsed strip renders one icon per tab (Gmail-style)
  /// instead of a single icon + label. Tapping a tab icon both selects it
  /// (via [onTabSelected]) and expands the panel (via [onToggle]).
  final List<SidebarTabItem>? railTabs;
  final int? selectedTabIndex;
  final ValueChanged<int>? onTabSelected;

  static const double _collapsedWidth = 44.0;
  static const Duration _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final expandedWidth = this.expandedWidth ?? MediaQuery.sizeOf(context).width * 0.4;
    final tabs = railTabs;
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeInOut,
      width: isExpanded ? expandedWidth : _collapsedWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: showLeftBorder
            ? const Border(left: BorderSide(color: Color(0xFFE5E7EB)))
            : null,
      ),
      child: ClipRect(
        child: isExpanded
            ? child
            : (tabs != null && tabs.isNotEmpty)
                ? CollapsedTabRail(
                    tabs: tabs,
                    selectedIndex: selectedTabIndex ?? 0,
                    onExpand: onToggle,
                    onTabSelected: (i) {
                      onTabSelected?.call(i);
                      onToggle();
                    },
                  )
                : CollapsedRailSegment(
                    onTap: onToggle,
                    label: collapsedLabel,
                    icon: collapsedIcon,
                    tooltip: collapsedTooltip,
                  ),
      ),
    );
  }
}

/// Gmail-style collapsed rail: an expand arrow on top, followed by one
/// icon button per tab. The currently selected tab's icon is highlighted
/// even while collapsed, so which section will show up on expand is clear.
class CollapsedTabRail extends StatelessWidget {
  const CollapsedTabRail({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onExpand,
    required this.onTabSelected,
  });

  final List<SidebarTabItem> tabs;
  final int selectedIndex;
  final VoidCallback onExpand;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _RailIconButton(
            icon: Icons.keyboard_double_arrow_left_rounded,
            tooltip: 'Tampilkan Sidebar',
            selected: false,
            onTap: onExpand,
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          for (var i = 0; i < tabs.length; i++)
            _RailIconButton(
              icon: tabs[i].icon,
              tooltip: tabs[i].label,
              selected: i == selectedIndex,
              onTap: () => onTabSelected(i),
            ),
        ],
      ),
    );
  }
}

class _RailIconButton extends StatefulWidget {
  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RailIconButton> createState() => _RailIconButtonState();
}

class _RailIconButtonState extends State<_RailIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? const Color(0xFF2563EB)
        : _hovered
            ? const Color(0xFF2563EB)
            : const Color(0xFF9CA3AF);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? const Color(0xFFDBEAFE)
                  : _hovered
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

/// A single collapsed-rail segment: icon + rotated label, click to re-open.
///
/// Used standalone inside [RiwayatAnimatedPanel] when only one section is
/// collapsed, and stacked (via [DualCollapsedRail]) when two adjacent
/// sidebar sections are collapsed at once so they share a single 44px rail
/// instead of appearing as two separate side-by-side strips.
class CollapsedRailSegment extends StatefulWidget {
  const CollapsedRailSegment({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final String tooltip;

  @override
  State<CollapsedRailSegment> createState() => _CollapsedRailSegmentState();
}

class _CollapsedRailSegmentState extends State<CollapsedRailSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _hovered ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF);
    return Tooltip(
      message: widget.tooltip,
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
                Icon(widget.icon, size: 18, color: color),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    widget.label,
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

/// A single 44px-wide rail that stacks 1–2 [CollapsedRailSegment]s
/// vertically, so two adjacent sidebar sections that are both collapsed
/// share one strip instead of appearing as two separate side-by-side ones.
class DualCollapsedRail extends StatelessWidget {
  const DualCollapsedRail({
    super.key,
    required this.segments,
    this.showLeftBorder = true,
  });

  final List<CollapsedRailSegment> segments;
  final bool showLeftBorder;

  static const double width = 44.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: showLeftBorder
            ? const Border(left: BorderSide(color: Color(0xFFE5E7EB)))
            : null,
      ),
      child: Column(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(child: segments[i]),
          ],
        ],
      ),
    );
  }
}
