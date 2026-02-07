// lib/common/widgets/states/error_state.dart

import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/primary_button.dart';

/// Generic error state widget with icon, message, and retry action
///
/// Example:
/// ```dart
/// ErrorState(
///   message: 'Failed to load data',
///   onRetry: () => fetchData(),
/// )
/// ```
class ErrorState extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Callback for retry action
  final VoidCallback onRetry;

  /// Title text (default: 'Error Loading Data')
  final String title;

  /// Icon to display (default: error_outline)
  final IconData icon;

  /// Size of the icon container (default: 80)
  final double iconSize;

  /// Retry button label (default: 'Try Again')
  final String retryLabel;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Error Loading Data',
    this.icon = Icons.error_outline,
    this.iconSize = 80,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(iconSize / 2),
              ),
              child: Icon(
                icon,
                size: iconSize / 2,
                color: const Color(0xFFDE350B),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),

            const SizedBox(height: 12),

            // Error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B778C),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Retry button
            PrimaryButton(
              onPressed: onRetry,
              label: retryLabel,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
