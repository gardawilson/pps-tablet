import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final double height;
  final bool busy;
  final bool isError;

  final IconData icon;
  final Color iconColor;
  final String text;

  final int maxLines;

  const InfoBox({
    super.key,
    required this.height,
    required this.busy,
    required this.isError,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError ? Colors.red.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade800,
                  height: 1.25,
                ),
              ),
            ),
            if (busy) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
