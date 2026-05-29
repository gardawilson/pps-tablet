import 'package:flutter/material.dart';

import 'production_panel_decoration.dart';

class ProductionOutputActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ProductionOutputActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductionTempCardOptionsDialog extends StatelessWidget {
  final String labelTitle;
  final bool showSebagian;
  final bool showPartial;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;

  const ProductionTempCardOptionsDialog({
    super.key,
    required this.labelTitle,
    this.showSebagian = true,
    this.showPartial = true,
    required this.primaryColor,
    this.surfaceColor = kProductionSurface,
    this.borderColor = kProductionBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (showSebagian) ...[
                    _ProductionTempOptionTile(
                      icon: Icons.checklist_rounded,
                      title: 'Sebagian Pallet',
                      value: 'select',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showPartial) ...[
                    _ProductionTempOptionTile(
                      icon: Icons.call_split_rounded,
                      title: 'Partial',
                      value: 'partial',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ProductionTempOptionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus Temp',
                    value: 'delete',
                    primaryColor: primaryColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    isDestructive: true,
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

class _ProductionTempOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDestructive;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;

  const _ProductionTempOptionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : primaryColor;
    return Material(
      color: isDestructive ? Colors.red.shade50 : surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDestructive ? Colors.red.shade200 : borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
