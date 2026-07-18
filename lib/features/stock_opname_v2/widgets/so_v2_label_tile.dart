import 'package:flutter/material.dart';

import '../model/so_v2_label_row.dart';

const _kBorder = Color(0xFFE2E6EA);
const _kSuccess = Color(0xFF0A7349);

class SoV2LabelTile extends StatelessWidget {
  final SoV2LabelRow row;
  final String weightUnit;

  const SoV2LabelTile({super.key, required this.row, this.weightUnit = 'kg'});

  @override
  Widget build(BuildContext context) {
    final scanned = row.isScanned;
    final value = row.weightOrCountDisplay(weightUnit: weightUnit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: scanned ? const Color(0xFFF3FBF7) : Colors.white,
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Icon(
            scanned ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: scanned ? _kSuccess : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.primaryValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scanned ? _kSuccess : const Color(0xFF1A1D23),
              ),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
