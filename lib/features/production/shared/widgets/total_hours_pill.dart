import 'package:flutter/material.dart';

class TotalHoursPill extends StatelessWidget {
  final Duration? duration;
  final bool isError;
  final String? errorText;
  final bool dense;
  final double minWidth;

  const TotalHoursPill({
    super.key,
    required this.duration,
    this.isError = false,
    this.errorText,
    this.dense = true,
    this.minWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final d = duration;

    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    // ✅ VALID
    if (!isError && d != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Container(
          padding: pad,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: dense ? 16 : 18, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                _formatShort(d),
                style: TextStyle(
                  fontSize: dense ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ❗ ERROR → gunakan Tooltip dengan trigger tap
    if (isError) {
      final msg = errorText ?? 'Durasi tidak valid';
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Tooltip(
          message: msg,
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: false,
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white),
          child: Container(
            padding: pad,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: dense ? 16 : 18, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Text(
                  '–',
                  style: TextStyle(
                    fontSize: dense ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ⏱️ NETRAL
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              '–',
              style: TextStyle(
                fontSize: dense ? 13 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (m == 0) return '$h j';
    if (h == 0) return '$m m';
    return '${h}j ${m}m';
  }
}
