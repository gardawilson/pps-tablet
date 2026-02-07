// lib/common/widgets/states/loading_state.dart

import 'package:flutter/material.dart';

/// Generic loading state widget with spinner and message
///
/// Example:
/// ```dart
/// LoadingState(message: 'Loading data...')
/// ```
class LoadingState extends StatelessWidget {
  /// Loading message to display below spinner
  final String message;

  /// Size of the spinner (default: 40)
  final double spinnerSize;

  /// Color of the spinner (default: primary blue)
  final Color? spinnerColor;

  const LoadingState({
    super.key,
    this.message = 'Loading...',
    this.spinnerSize = 40,
    this.spinnerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                spinnerColor ?? const Color(0xFF0052CC),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF42526E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
