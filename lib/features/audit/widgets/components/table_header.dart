import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final String tableName;
  final String action;
  final int itemCount;

  const TableHeader({
    super.key,
    required this.tableName,
    required this.action,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7), // N20
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFDFE1E6)), // N40
      ),
      child: Row(
        children: [
          // Table Icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(
              Icons.table_chart_outlined,
              size: 16,
              color: Color(0xFF42526E), // N300
            ),
          ),

          const SizedBox(width: 10),

          // Table Name
          Expanded(
            child: Text(
              tableName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D), // N800
                letterSpacing: -0.003,
              ),
            ),
          ),

          // Action Badge (optional)
          if (action.isNotEmpty && action != '-') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFDFE1E6)), // N40
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B778C), // N200
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Item Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDFE1E6), // N40
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$itemCount',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF42526E), // N300
              ),
            ),
          ),
        ],
      ),
    );
  }
}
