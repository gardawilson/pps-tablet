import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';
import 'package:pps_tablet/core/utils/model_helpers.dart';
import 'package:pps_tablet/features/audit/model/audit_session_model.dart';
import '../components/action_lozenge.dart';
import '../components/count_badge.dart';
import '../components/table_header.dart';
import '../components/flow_arrow.dart';
import '../components/source_chip.dart';
import '../components/label_card.dart';
import '../components/attribute_badge.dart';

class ProduceUnproduceSection extends StatelessWidget {
  final AuditSession session;

  const ProduceUnproduceSection({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final hasProduce = session.produceGroups.isNotEmpty;
    final hasUnproduce = session.unproduceGroups.isNotEmpty;

    if (!hasProduce && !hasUnproduce) {
      return CardContainer(
        child: Text(
          'No production data.',
          style: const TextStyle(color: Color(0xFF6B778C), fontSize: 14),
        ),
      );
    }

    // =============================
    // 🔥 ADJUST MODE
    // =============================
    if (session.isAdjust) {
      final addedGroups = session.produceGroups;
      final removedGroups = session.unproduceDiffGroups;

      final addedCount = session.produceAddedCount;
      final removedCount = session.produceRemovedCount;

      return CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ActionLozenge(action: 'ADJUST'),
                const Spacer(),
                CountBadge(count: addedCount + removedCount),
              ],
            ),
            const SizedBox(height: 20),

            if (addedGroups.isNotEmpty) ...[
              _SectionTitle(title: 'Added Output', count: addedCount),
              const SizedBox(height: 12),
              ..._buildGroups(groups: addedGroups, isUnproduce: false),
              const SizedBox(height: 24),
            ],

            if (removedGroups.isNotEmpty) ...[
              _SectionTitle(title: 'Removed Output', count: removedCount),
              const SizedBox(height: 12),
              ..._buildGroups(groups: removedGroups, isUnproduce: true),
            ],
          ],
        ),
      );
    }

    // =============================
    // PRODUCE / UNPRODUCE (LEGACY)
    // =============================
    final isProduce = hasProduce && !hasUnproduce;
    final groups = isProduce ? session.produceGroups : session.unproduceGroups;

    final totalCount = groups.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ActionLozenge(action: isProduce ? 'PRODUCE' : 'UNPRODUCE'),
              const Spacer(),
              CountBadge(count: totalCount),
            ],
          ),
          const SizedBox(height: 20),
          ..._buildGroups(groups: groups, isUnproduce: !isProduce),
        ],
      ),
    );
  }

  // =============================
  // Shared group builder
  // =============================
  List<Widget> _buildGroups({
    required Map<String, List<Map<String, dynamic>>> groups,
    required bool isUnproduce,
  }) {
    return groups.entries.map((entry) {
      final parts = entry.key.split('|');
      final tableName = parts.first;
      final action = parts.length > 1 ? parts.last : '-';

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _ProduceGroup(
          tableName: tableName,
          action: action,
          items: entry.value,
          isUnproduce: isUnproduce,
        ),
      );
    }).toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF172B4D),
          ),
        ),
        const SizedBox(width: 8),
        CountBadge(count: count),
      ],
    );
  }
}

// =============================
// Produce Group
// =============================
class _ProduceGroup extends StatelessWidget {
  final String tableName;
  final String action;
  final List<Map<String, dynamic>> items;
  final bool isUnproduce;

  const _ProduceGroup({
    required this.tableName,
    required this.action,
    required this.items,
    required this.isUnproduce,
  });

  @override
  Widget build(BuildContext context) {
    final firstRow = items.isNotEmpty ? items.first : {};
    final noProduksi = pickS(firstRow as Map<String, dynamic>, [
      'NoProduksi',
      'NoCrusherProduksi',
      'NoPacking',
      'NoBJSortir',
      'NoBJJual',
      'NoRetur',
      'NoBongkarSusun',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableHeader(
          tableName: tableName,
          action: action,
          itemCount: items.length,
        ),

        const SizedBox(height: 12),

        _ProductionFlow(
          sourceLabelNo: noProduksi ?? '-',
          items: items,
          isUnproduce: isUnproduce,
        ),
      ],
    );
  }
}

// =============================
// Production Flow
// =============================
class _ProductionFlow extends StatelessWidget {
  final String sourceLabelNo;
  final List<Map<String, dynamic>> items;
  final bool isUnproduce;

  const _ProductionFlow({
    required this.sourceLabelNo,
    required this.items,
    required this.isUnproduce,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC), // N10
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFEBECF0)), // N30
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: SourceChip(label: sourceLabelNo)),
            FlowArrow(isRemoval: isUnproduce),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.asMap().entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key < items.length - 1 ? 8 : 0,
                    ),
                    child: _OutputLabelCard(
                      row: entry.value,
                      isRemoved: isUnproduce,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================
// Output Label Card
// =============================
class _OutputLabelCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isRemoved;

  const _OutputLabelCard({required this.row, this.isRemoved = false});

  @override
  Widget build(BuildContext context) {
    final labelNo =
        row['NoBroker']?.toString() ??
        row['NoWashing']?.toString() ??
        row['NoBonggolan']?.toString() ??
        row['NoCrusher']?.toString() ??
        row['NoGilingan']?.toString() ??
        row['NoMixer']?.toString() ??
        row['NoFurnitureWIP']?.toString() ??
        row['NoBJ']?.toString() ??
        '-';

    final attributes = _buildAttributes();

    return LabelCard(
      labelNo: labelNo,
      attributes: attributes,
      isRemoved: isRemoved,
    );
  }

  List<Widget> _buildAttributes() {
    final List<Widget> badges = [];

    if (row['NoSak'] != null) {
      badges.add(
        AttributeBadge(
          icon: Icons.widgets_outlined,
          label: 'Sak #${row['NoSak']}',
          bgColor: const Color(0xFFDEEBFF),
          textColor: const Color(0xFF0747A6),
        ),
      );
    }

    if (row['Berat'] != null) {
      final berat = row['Berat'];
      final beratKg = (berat is num)
          ? berat.toStringAsFixed(2)
          : berat.toString();

      badges.add(
        AttributeBadge(
          icon: Icons.scale_outlined,
          label: '$beratKg kg',
          bgColor: const Color(0xFFFFF0B3),
          textColor: const Color(0xFF172B4D),
        ),
      );
    }

    if (row['Pcs'] != null) {
      badges.add(
        AttributeBadge(
          icon: Icons.confirmation_number_outlined,
          label: '${row['Pcs']} pcs',
          bgColor: const Color(0xFFE3FCEF),
          textColor: const Color(0xFF006644),
        ),
      );
    }

    return badges;
  }
}
