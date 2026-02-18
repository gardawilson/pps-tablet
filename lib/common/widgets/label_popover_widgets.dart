import 'package:flutter/material.dart';

class LabelPopoverStatusLozenge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const LabelPopoverStatusLozenge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class LabelPopoverMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? tooltipWhenDisabled;
  final Color? iconColor;
  final TextStyle? textStyle;

  const LabelPopoverMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.tooltipWhenDisabled,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    const atlasBlue = Color(0xFF0C66E4);
    const atlasText = Color(0xFF172B4D);
    const atlasSubtle = Color(0xFF6B778C);

    final effectiveIconColor = enabled
        ? (iconColor ?? atlasBlue)
        : Colors.grey.shade500;
    final effectiveTextStyle =
        (textStyle ??
                const TextStyle(
                  color: atlasText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ))
            .copyWith(
              color: enabled ? (textStyle?.color ?? atlasText) : atlasSubtle,
            );

    final tile = InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: enabled
                    ? effectiveIconColor.withOpacity(0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: effectiveTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: enabled ? atlasSubtle : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );

    if (!enabled && (tooltipWhenDisabled?.isNotEmpty ?? false)) {
      return Tooltip(
        message: tooltipWhenDisabled!,
        child: Opacity(opacity: 0.58, child: tile),
      );
    }
    return tile;
  }
}
