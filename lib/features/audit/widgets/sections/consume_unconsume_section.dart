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
import '../components/change_badge.dart';

class ConsumeUnconsumeSection extends StatelessWidget {
  final AuditSession session;

  const ConsumeUnconsumeSection({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final isConsume = session.isConsume;
    final groups = isConsume ? session.consumeGroups : session.unconsumeGroups;

    if (groups.isEmpty) {
      return CardContainer(
        child: Text(
          'No ${isConsume ? 'consumption' : 'unconsumption'} data.',
          style: const TextStyle(color: Color(0xFF6B778C), fontSize: 14),
        ),
      );
    }

    final totalCount = groups.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              ActionLozenge(action: isConsume ? 'CONSUME' : 'UNCONSUME'),
              const Spacer(),
              CountBadge(count: totalCount),
            ],
          ),

          const SizedBox(height: 20),

          // Groups
          ...groups.entries.map((entry) {
            final parts = entry.key.split('|');
            final tableName = parts.isNotEmpty ? parts.first : '-';
            final action = parts.length > 1 ? parts.last : '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ConsumeGroup(
                tableName: tableName,
                action: action,
                items: entry.value,
                isUnconsume: !isConsume,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================
// Consume Group
// =============================
class _ConsumeGroup extends StatelessWidget {
  final String tableName;
  final String action;
  final List<Map<String, dynamic>> items;
  final bool isUnconsume;

  const _ConsumeGroup({
    required this.tableName,
    required this.action,
    required this.items,
    required this.isUnconsume,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil NoProduksi dari item pertama (semua sama)
    final firstRow = items.isNotEmpty ? items.first : {};
    final noProduksi = pickS(firstRow as Map<String, dynamic>, [
      'NoProduksi',
      'NoCrusherProduksi',
      'NoPacking',
      'NoBJSortir',
      'NoBJJual',
      'NoBongkarSusun',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header - Using Shared Component
        TableHeader(
          tableName: tableName,
          action: action,
          itemCount: items.length,
        ),

        const SizedBox(height: 12),

        // Consumption Flow
        _ConsumptionFlow(
          targetProduksiNo: noProduksi ?? '-',
          items: items,
          isUnconsume: isUnconsume,
        ),
      ],
    );
  }
}

// =============================
// Consumption Flow
// =============================
class _ConsumptionFlow extends StatelessWidget {
  final String targetProduksiNo;
  final List<Map<String, dynamic>> items;
  final bool isUnconsume;

  const _ConsumptionFlow({
    required this.targetProduksiNo,
    required this.items,
    required this.isUnconsume,
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
            if (isUnconsume) ...[
              // UNCONSUME: Produksi → Labels (removed)
              Center(child: SourceChip(label: targetProduksiNo)),

              FlowArrow(isRemoval: true),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < items.length - 1 ? 8 : 0,
                      ),
                      child: _InputLabelCard(row: entry.value, isRemoved: true),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              // CONSUME: Labels → Produksi (added)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < items.length - 1 ? 8 : 0,
                      ),
                      child: _InputLabelCard(
                        row: entry.value,
                        isRemoved: false,
                      ),
                    );
                  }).toList(),
                ),
              ),

              FlowArrow(isRemoval: false),

              Center(child: SourceChip(label: targetProduksiNo)),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================
// Input Label Card (Private - builds attributes internally)
// =============================
class _InputLabelCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isRemoved;

  const _InputLabelCard({required this.row, required this.isRemoved});

  @override
  Widget build(BuildContext context) {
    // Extract label number
    final labelNo =
        row['NoBahanBaku']?.toString() ??
        row['NoWashing']?.toString() ??
        row['NoBroker']?.toString() ??
        row['NoCrusher']?.toString() ??
        row['NoGilingan']?.toString() ??
        row['NoMixer']?.toString() ??
        row['NoFurnitureWIP']?.toString() ??
        row['NoBJ']?.toString() ??
        '-';

    // Build attributes using shared components
    final attributes = _buildAttributes();

    // Use shared AuditLabelCard
    return LabelCard(
      labelNo: labelNo,
      attributes: attributes,
      isRemoved: isRemoved,
    );
  }

  List<Widget> _buildAttributes() {
    final List<Widget> badges = [];

    // Sak Badge - Blue
    if (row['NoSak'] != null) {
      badges.add(
        AttributeBadge(
          icon: Icons.widgets_outlined,
          label: 'Sak #${row['NoSak']}',
          bgColor: const Color(0xFFDEEBFF), // B50
          textColor: const Color(0xFF0747A6), // B500
        ),
      );
    }

    // Handle Pcs (old/new or simple value)
    final oldPcs = asInt(row['OldPcs']);
    final newPcs = asInt(row['NewPcs']);
    final pcs = asInt(row['Pcs']);

    final hasOldNewPcs = (oldPcs != null || newPcs != null);
    if (hasOldNewPcs && oldPcs != newPcs) {
      badges.add(
        ChangeBadge(
          icon: Icons.confirmation_number_outlined,
          label: 'Pcs',
          oldValue: oldPcs?.toString() ?? '-',
          newValue: newPcs?.toString() ?? '-',
        ),
      );
    } else if (pcs != null) {
      badges.add(
        AttributeBadge(
          icon: Icons.confirmation_number_outlined,
          label: '$pcs pcs',
          bgColor: const Color(0xFFE3FCEF), // G50
          textColor: const Color(0xFF006644), // G500
        ),
      );
    }

    // Handle Berat (old/new or simple value)
    final oldBerat = pickN(row, ['OldBerat']);
    final newBerat = pickN(row, ['NewBerat']);
    final berat = row['Berat'];

    final hasOldNewBerat = (oldBerat != null || newBerat != null);
    if (hasOldNewBerat && oldBerat != newBerat) {
      final oldBeratStr = oldBerat != null
          ? (oldBerat.toStringAsFixed(2))
          : '-';
      final newBeratStr = newBerat != null
          ? (newBerat.toStringAsFixed(2))
          : '-';

      badges.add(
        ChangeBadge(
          icon: Icons.scale_outlined,
          label: 'Berat',
          oldValue: '$oldBeratStr kg',
          newValue: '$newBeratStr kg',
        ),
      );
    } else if (berat != null) {
      final beratStr = berat is num
          ? berat.toStringAsFixed(2)
          : berat.toString();

      badges.add(
        AttributeBadge(
          icon: Icons.scale_outlined,
          label: '$beratStr kg',
          bgColor: const Color(0xFFFFF0B3), // Y50
          textColor: const Color(0xFF172B4D), // N800
        ),
      );
    }

    return badges;
  }
}
