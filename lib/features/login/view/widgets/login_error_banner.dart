// lib/features/login/view/widgets/login_error_banner.dart
import 'package:flutter/material.dart';

class LoginErrorBanner extends StatelessWidget {
  final String message;
  final String errorType;

  const LoginErrorBanner({
    super.key,
    required this.message,
    required this.errorType,
  });

  Color _color() {
    switch (errorType) {
      case 'auth':
        return Colors.red;
      case 'network':
        return Colors.orange;
      case 'server':
      case 'maintenance':
        return Colors.deepOrange;
      case 'validation':
        return Colors.redAccent;
      default:
        return Colors.red;
    }
  }

  IconData _icon() {
    switch (errorType) {
      case 'auth':
        return Icons.lock_outline;
      case 'network':
        return Icons.wifi_off_rounded;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'server':
        return Icons.cloud_off_rounded;
      case 'validation':
        return Icons.info_outline;
      default:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    final c = _color();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(_icon(), color: c, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: c, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
