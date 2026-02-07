import 'package:flutter/material.dart';

class FlowArrow extends StatelessWidget {
  final bool isRemoval;

  const FlowArrow({super.key, required this.isRemoval});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          isRemoval ? Icons.call_made_rounded : Icons.arrow_forward_rounded,
          size: 24,
          color: isRemoval
              ? const Color(0xFFDE350B) // R400 - Red untuk removal
              : const Color(0xFF006644), // G500 - Green untuk creation
        ),
      ),
    );
  }
}
