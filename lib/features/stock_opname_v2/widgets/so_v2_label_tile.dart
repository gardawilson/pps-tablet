import 'package:flutter/material.dart';

import '../model/so_v2_label_row.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);

class SoV2LabelTile extends StatelessWidget {
  final SoV2LabelRow row;

  const SoV2LabelTile({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final scanned = row.isScanned;
    final value = row.weightOrCountDisplay;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scanned ? const Color(0xFFF0FBF6) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scanned ? const Color(0xFF0A7349) : _kBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            scanned ? Icons.check_circle_rounded : Icons.label_outline_rounded,
            size: 15,
            color: scanned ? const Color(0xFF0A7349) : _kPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.primaryValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
