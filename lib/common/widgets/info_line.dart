import 'package:flutter/material.dart';

class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const InfoLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
