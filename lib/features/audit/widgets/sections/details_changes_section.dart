import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';
import 'package:pps_tablet/common/widgets/simple_divider.dart';
import '../../model/audit_session_model.dart';

class DetailsChangesSection extends StatelessWidget {
  final AuditSession session;

  const DetailsChangesSection({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final oldList = session.detailsOldList ?? [];
    final newList = session.detailsNewList ?? [];
    final comparisonData = _buildComparisonData(oldList, newList);

    final added = comparisonData.where((c) => c.status == 'ADDED').length;
    final deleted = comparisonData.where((c) => c.status == 'DELETED').length;
    final modified = comparisonData.where((c) => c.status == 'MODIFIED').length;

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (deleted > 0)
                _StatusLozenge(
                  label: 'Deleted',
                  count: deleted,
                  color: const Color(0xFFDE350B),
                  bgColor: const Color(0xFFFFEBEB),
                ),
              if (added > 0)
                _StatusLozenge(
                  label: 'Added',
                  count: added,
                  color: const Color(0xFF36B37E),
                  bgColor: const Color(0xFFE3FCEF),
                ),
              if (modified > 0)
                _StatusLozenge(
                  label: 'Modified',
                  count: modified,
                  color: const Color(0xFFFF991F),
                  bgColor: const Color(0xFFFFF0E5),
                ),
            ],
          ),

          if (comparisonData.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SimpleDivider(),
            const SizedBox(height: 16),

            ...comparisonData.map(
              (comparison) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DetailChangeRow(comparison: comparison),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================
  // Comparison Builder
  // =============================
  List<_DetailComparison> _buildComparisonData(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    final oldMap = <int, Map<String, dynamic>>{
      for (final item in oldList)
        if (item['NoSak'] != null) item['NoSak'] as int: item,
    };

    final newMap = <int, Map<String, dynamic>>{
      for (final item in newList)
        if (item['NoSak'] != null) item['NoSak'] as int: item,
    };

    final allNoSak = <int>{...oldMap.keys, ...newMap.keys}.toList()..sort();

    return allNoSak.map((noSak) {
      final oldItem = oldMap[noSak];
      final newItem = newMap[noSak];

      final status = oldItem != null && newItem == null
          ? 'DELETED'
          : oldItem == null && newItem != null
          ? 'ADDED'
          : _itemsAreDifferent(oldItem, newItem)
          ? 'MODIFIED'
          : 'UNCHANGED';

      return _DetailComparison(
        noSak: noSak,
        oldItem: oldItem,
        newItem: newItem,
        status: status,
      );
    }).toList();
  }

  bool _itemsAreDifferent(
    Map<String, dynamic>? oldItem,
    Map<String, dynamic>? newItem,
  ) {
    if (oldItem == null || newItem == null) return true;
    return oldItem['Berat'] != newItem['Berat'] ||
        oldItem['IsPartial'] != newItem['IsPartial'] ||
        oldItem['DateUsage'] != newItem['DateUsage'];
  }
}

// =============================
// UI Components
// =============================
class _StatusLozenge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatusLozenge({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailChangeRow extends StatelessWidget {
  final _DetailComparison comparison;

  const _DetailChangeRow({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(comparison.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: config.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: config.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sak #${comparison.noSak}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: config.textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: config.dotColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  comparison.status,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (comparison.oldItem != null || comparison.newItem != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (comparison.oldItem != null)
                  Expanded(
                    child: _DetailItemDisplay(
                      label: 'Before',
                      item: comparison.oldItem!,
                    ),
                  ),
                if (comparison.oldItem != null && comparison.newItem != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF6B778C),
                    ),
                  ),
                if (comparison.newItem != null)
                  Expanded(
                    child: _DetailItemDisplay(
                      label: 'After',
                      item: comparison.newItem!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'DELETED':
        return _StatusConfig(
          bgColor: const Color(0xFFFFEBEB),
          borderColor: const Color(0xFFFFBDAD),
          dotColor: const Color(0xFFDE350B),
          textColor: const Color(0xFFBF2600),
        );
      case 'ADDED':
        return _StatusConfig(
          bgColor: const Color(0xFFE3FCEF),
          borderColor: const Color(0xFF79F2C0),
          dotColor: const Color(0xFF36B37E),
          textColor: const Color(0xFF006644),
        );
      case 'MODIFIED':
        return _StatusConfig(
          bgColor: const Color(0xFFFFF0E5),
          borderColor: const Color(0xFFFFD79E),
          dotColor: const Color(0xFFFF991F),
          textColor: const Color(0xFF974F0C),
        );
      default:
        return _StatusConfig(
          bgColor: const Color(0xFFF4F5F7),
          borderColor: const Color(0xFFDFE1E6),
          dotColor: const Color(0xFF6B778C),
          textColor: const Color(0xFF42526E),
        );
    }
  }
}

class _DetailItemDisplay extends StatelessWidget {
  final String label;
  final Map<String, dynamic> item;

  const _DetailItemDisplay({required this.label, required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (item['Berat'] != null) parts.add('${item['Berat']} kg');
    if (item['IsPartial'] == true) parts.add('Partial');
    if (item['DateUsage'] != null) {
      parts.add('Used: ${item['DateUsage']}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B778C),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          parts.isNotEmpty ? parts.join(' • ') : '-',
          style: const TextStyle(fontSize: 12, color: Color(0xFF172B4D)),
        ),
      ],
    );
  }
}

// =============================
// Models
// =============================
class _DetailComparison {
  final int noSak;
  final Map<String, dynamic>? oldItem;
  final Map<String, dynamic>? newItem;
  final String status;

  _DetailComparison({
    required this.noSak,
    this.oldItem,
    this.newItem,
    required this.status,
  });
}

class _StatusConfig {
  final Color bgColor;
  final Color borderColor;
  final Color dotColor;
  final Color textColor;

  _StatusConfig({
    required this.bgColor,
    required this.borderColor,
    required this.dotColor,
    required this.textColor,
  });
}
