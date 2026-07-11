import 'package:flutter/material.dart';

/// Slim header for an expanded Gmail-style sidebar panel: a collapse arrow
/// plus the current section's title. Switching sections happens via the
/// collapsed icon rail ([CollapsedTabRail]), so no in-panel tab switcher
/// is needed here.
class SidebarPanelHeader extends StatelessWidget {
  const SidebarPanelHeader({
    super.key,
    required this.title,
    required this.onToggle,
    this.trailing,
  });

  final String title;
  final VoidCallback onToggle;

  /// Optional widget shown at the end of the title row — e.g. a "Semua"
  /// filter chip — so it doesn't need its own separate header bar below.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      child: Row(
        children: [
          Tooltip(
            message: 'Sembunyikan Sidebar',
            waitDuration: const Duration(milliseconds: 400),
            child: IconButton(
              onPressed: onToggle,
              icon: const Icon(
                Icons.keyboard_double_arrow_right_rounded,
                size: 16,
              ),
              color: const Color(0xFF9CA3AF),
              hoverColor: const Color(0xFFEFF6FF),
              highlightColor: const Color(0xFFDBEAFE),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SidebarTabItem {
  const SidebarTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Segmented tab switcher used at the top of a collapsible sidebar panel
/// that hosts more than one section (e.g. Riwayat Produksi / Stok Item),
/// so only one section is visible at a time instead of splitting the
/// sidebar width/height between them.
class SidebarTabSwitcher extends StatelessWidget {
  const SidebarTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.onToggle,
  });

  final List<SidebarTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          if (onToggle != null) ...[
            Tooltip(
              message: 'Sembunyikan Sidebar',
              waitDuration: const Duration(milliseconds: 400),
              child: IconButton(
                onPressed: onToggle,
                icon: const Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  size: 16,
                ),
                color: const Color(0xFF9CA3AF),
                hoverColor: const Color(0xFFEFF6FF),
                highlightColor: const Color(0xFFDBEAFE),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(child: _buildTab(context, i)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final tab = tabs[index];
    final selected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 15,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
