import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';

class LabelCard extends StatelessWidget {
  final String labelNo;
  final List<Widget> attributes;
  final bool isRemoved;

  const LabelCard({
    super.key,
    required this.labelNo,
    required this.attributes,
    this.isRemoved = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 3,
      borderColor: isRemoved
          ? const Color(0xFFDE350B) // R400 - Red border untuk removed
          : const Color(0xFFDFE1E6), // N40 - Normal border
      borderWidth: 1,
      showShadow: true,
      customShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7), // N20
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  isRemoved ? Icons.remove_circle_outline : Icons.label_outline,
                  size: 14,
                  color: isRemoved
                      ? const Color(0xFFDE350B) // R400
                      : const Color(0xFF6B778C), // N200
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labelNo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isRemoved
                        ? const Color(0xFF6B778C) // Muted untuk removed
                        : const Color(0xFF172B4D), // N800 normal
                    letterSpacing: -0.003,
                    decoration: isRemoved
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: const Color(0xFFDE350B), // R400
                    decorationThickness: 2,
                  ),
                ),
              ),
            ],
          ),

          // Attributes
          if (attributes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: attributes),
          ],
        ],
      ),
    );
  }
}
