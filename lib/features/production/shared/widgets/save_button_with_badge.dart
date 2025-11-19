// lib/features/production/broker/widgets/save_button_with_badge.dart
import 'package:flutter/material.dart';

class SaveButtonWithBadge extends StatelessWidget {
  final int count;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? tooltip;

  const SaveButtonWithBadge({
    super.key,
    required this.count,
    this.isLoading = false,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems = count > 0;
    final canPress = hasItems && !isLoading && onPressed != null;

    return IconButton(
      tooltip: tooltip ?? (hasItems ? 'Simpan $count item temp' : 'Tidak ada data untuk disimpan'),
      onPressed: canPress ? onPressed : null,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          // Save Icon
          isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Icon(
            Icons.save,
            color: canPress ? Colors.green : Colors.grey,
            size: 24,
          ),

          // Badge Counter
          if (hasItems && !isLoading)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}