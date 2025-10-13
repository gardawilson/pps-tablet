// common/widgets/success_status_dialog.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class StatusAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary; // true = filled, false = outlined

  const StatusAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });
}

class SuccessStatusDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? extraContent;
  final double maxWidth;

  /// Default actions: satu tombol "OK" yang menutup dialog.
  final List<StatusAction>? actions;

  const SuccessStatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.extraContent,
    this.maxWidth = 420,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = math.min(maxWidth, screenW * 0.9);

    final buttons = (actions == null || actions!.isEmpty)
        ? <StatusAction>[
      StatusAction(
        label: 'OK',
        onPressed: () => Navigator.of(context).pop(),
        isPrimary: true,
      )
    ]
        : actions!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 300, maxWidth: dialogW),
        child: SizedBox(
          width: dialogW,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.green),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black45),
                ),
                if (extraContent != null) ...[
                  const SizedBox(height: 12),
                  extraContent!,
                ],
                const SizedBox(height: 24),

                // Tombol: 1 = full width, >=2 = dua/lebih sejajar
                if (buttons.length == 1)
                  SizedBox(
                    width: double.infinity,
                    child: _buildButton(context, buttons.first),
                  )
                else
                  Row(
                    children: [
                      for (int i = 0; i < buttons.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: _buildButton(context, buttons[i])),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, StatusAction a) {
    final styleBase = ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14)),
    );

    return a.isPrimary
        ? ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ).merge(styleBase),
      onPressed: a.onPressed,
      child: Text(a.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    )
        : OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        foregroundColor: Colors.black87,
      ).merge(styleBase),
      onPressed: a.onPressed,
      child: Text(a.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
