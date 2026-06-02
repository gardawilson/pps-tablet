// lib/features/production/shared/widgets/production_folder_tab_bar.dart
//
// Dua varian tab bar untuk panel produksi:
//   • ProductionFolderTabBar  — folder-style (active tab menyatu ke content bawah)
//   • ProductionPanelTabBar   — pill-style biasa
//
// Keduanya menerima List<ProductionTabItem> yang generik.

import 'package:flutter/material.dart';
import 'production_panel_decoration.dart';

/// Data per-tab.
class ProductionTabItem {
  final String value;
  final String label;
  final int count;

  const ProductionTabItem({
    required this.value,
    required this.label,
    required this.count,
  });
}

// ── Folder-style tab bar ──────────────────────────────────────────────────────

/// Tab aktif menyatu secara visual ke blok konten di bawahnya.
class ProductionFolderTabBar extends StatelessWidget {
  final String selectedValue;
  final List<ProductionTabItem> tabs;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const ProductionFolderTabBar({
    super.key,
    required this.selectedValue,
    required this.tabs,
    required this.onChanged,
    this.accentColor = kProductionPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.32),
          width: 1.1,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: tabs.map((tab) {
            final isSelected = tab.value == selectedValue;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onChanged(tab.value),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(top: isSelected ? 0 : 4),
                      padding: EdgeInsets.fromLTRB(
                        10,
                        isSelected ? 7 : 5,
                        10,
                        isSelected ? 9 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFDDE1E7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(7),
                        ),
                        border: isSelected
                            ? Border.all(
                                color: accentColor.withValues(alpha: 0.32),
                                width: 1.1,
                              )
                            : Border.all(
                                color: const Color(0xFFC5CAD3),
                                width: 1,
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? accentColor
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.1)
                                  : const Color(0xFFC5CAD3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? accentColor
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Strip putih menutupi border bawah tab yang selected
                    if (isSelected)
                      Positioned(
                        bottom: 0,
                        left: 1.1,
                        right: 1.1,
                        child: Container(height: 2, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Pill-style tab bar ────────────────────────────────────────────────────────

/// Tab bergaya pill/chip — dipakai untuk output tab bar atau variasi lain.
class ProductionPanelTabBar extends StatelessWidget {
  final String selectedValue;
  final List<ProductionTabItem> tabs;
  final ValueChanged<String> onChanged;
  final Color accentColor;

  const ProductionPanelTabBar({
    super.key,
    required this.selectedValue,
    required this.tabs,
    required this.onChanged,
    this.accentColor = kProductionOutput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kProductionBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = tab.value == selectedValue;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onChanged(tab.value),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : kProductionBorder,
                            ),
                          ),
                          child: Text(
                            '${tab.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
