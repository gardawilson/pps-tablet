// lib/features/audit/widgets/audit_detail_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../common/widgets/card_container.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/info_row.dart';
import '../../../common/widgets/json_viewer.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/simple_divider.dart';
import '../../../core/utils/model_helpers.dart';
import '../view_model/audit_view_model.dart';
import '../model/audit_session_model.dart';

class AuditDetailPanel extends StatelessWidget {
  const AuditDetailPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditViewModel>(
      builder: (context, vm, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFBFC),
            border: Border(
              left: BorderSide(color: Color(0xFFDFE1E6), width: 1),
            ),
          ),
          child: Column(
            children: [
              // Atlassian-style Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFDFE1E6), width: 1),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: Color(0xFF42526E),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Activity Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF172B4D),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: vm.selectedSession != null
                    ? _SessionDetail(session: vm.selectedSession!)
                    : EmptyState(
                      icon: Icons.list_alt_outlined,
                      title: 'No activity selected',
                      subtitle: 'Select an activity from the list to view details',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionDetail extends StatelessWidget {
  final AuditSession session;

  const _SessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');
    final startTime = DateTime.tryParse(session.startTime);
    final endTime = DateTime.tryParse(session.endTime);

    final hasHeaderChanges =
        (session.oldValues.isNotEmpty || session.newValues.isNotEmpty) &&
            !session.isConsumeSession;

    final hasDetailsChanges =
        session.detailsOldList != null || session.detailsNewList != null;

    final hasConsumeBlock =
        (session.consumeUnifiedEvents != null &&
            session.consumeUnifiedEvents!.isNotEmpty) ||
            (session.consumeUnifiedItems != null &&
                session.consumeUnifiedItems!.isNotEmpty);

    final hasRaw = session.headerOld != null ||
        session.headerNew != null ||
        session.detailsOldJson != null ||
        session.detailsNewJson != null ||
        session.outputChanges != null ||
        session.consumeJson != null ||
        session.unconsumeJson != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Overview
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with action lozenge
                Row(
                  children: [
                    _AtlassianLozenge(action: session.sessionAction),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.documentNo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF172B4D),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Document Number',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B778C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const SimpleDivider(),
                const SizedBox(height: 20),

                // Info grid
                InfoRow(
                  icon: Icons.person_outline,
                  label: 'User',
                  value: session.actor,
                ),
                const SizedBox(height: 16),
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: startTime != null
                      ? dateFormat.format(startTime)
                      : '-',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'Start Time',
                        value: startTime != null
                            ? timeFormat.format(startTime)
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'End Time',
                        value: endTime != null
                            ? timeFormat.format(endTime)
                            : '-',
                      ),
                    ),
                  ],
                ),
                if (session.requestId != null) ...[
                  const SizedBox(height: 16),
                  InfoRow(
                    icon: Icons.fingerprint,
                    label: 'Request ID',
                    value: session.requestId!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Consume/Unconsume section
          if (hasConsumeBlock) ...[
            SectionHeader(
              icon: Icons.swap_horiz_outlined,
              title: session.isConsume ? 'Material Consumption' : 'Material Unconsumption',
            ),
            const SizedBox(height: 12),
            _ConsumeUnconsumeSection(session: session),
            const SizedBox(height: 16),
          ],

          // Header changes
          if (hasHeaderChanges) ...[
            const SectionHeader(
              icon: Icons.edit_note_outlined,
              title: 'Header Modifications',
            ),
            const SizedBox(height: 12),
            _HeaderChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // Details changes
          if (hasDetailsChanges && !session.isConsumeSession) ...[
            SectionHeader(
              icon: Icons.list_alt_outlined,
              title: 'Detail Line Changes',
              subtitle: session.detailsChangeSummary,
            ),
            const SizedBox(height: 12),
            _DetailsChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // Output relation
          if (session.outputDisplayValue != null) ...[
            const SectionHeader(
              icon: Icons.link,
              title: 'Output Relation',
            ),
            const SizedBox(height: 12),
            _OutputChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // Raw JSON section
          if (hasRaw) _RawDataSection(session: session),
        ],
      ),
    );
  }
}

// =============================
// Atlassian Lozenge
// =============================
class _AtlassianLozenge extends StatelessWidget {
  final String action;

  const _AtlassianLozenge({required this.action});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            action.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: config.textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _LozengeConfig _getConfig(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFE3FCEF),
          textColor: const Color(0xFF006644),
          dotColor: const Color(0xFF36B37E),
        );
      case 'UPDATE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFDEEBFF),
          textColor: const Color(0xFF0747A6),
          dotColor: const Color(0xFF0052CC),
        );
      case 'DELETE':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFEBEB),
          textColor: const Color(0xFFBF2600),
          dotColor: const Color(0xFFDE350B),
        );
      case 'CONSUME':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFFFF0E5),
          textColor: const Color(0xFF974F0C),
          dotColor: const Color(0xFFFF991F),
        );
      case 'UNCONSUME':
        return _LozengeConfig(
          backgroundColor: const Color(0xFFEAE6FF),
          textColor: const Color(0xFF403294),
          dotColor: const Color(0xFF6554C0),
        );
      default:
        return _LozengeConfig(
          backgroundColor: const Color(0xFFF4F5F7),
          textColor: const Color(0xFF42526E),
          dotColor: const Color(0xFF6B778C),
        );
    }
  }
}

class _LozengeConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color dotColor;

  _LozengeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.dotColor,
  });
}

// =============================
// Consume/Unconsume Section
// =============================
class _ConsumeUnconsumeSection extends StatelessWidget {
  final AuditSession session;

  const _ConsumeUnconsumeSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final isConsume = session.isConsume;
    final groups = isConsume ? session.consumeGroups : session.unconsumeGroups;

    if (groups.isEmpty) {
      return CardContainer(
        child: Text(
          'No ${isConsume ? 'consumption' : 'unconsumption'} data.',
          style: const TextStyle(
            color: Color(0xFF6B778C),
            fontSize: 14,
          ),
        ),
      );
    }

    final totalCount = groups.values.fold<int>(0, (sum, list) => sum + list.length);

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _AtlassianLozenge(
                action: isConsume ? 'CONSUME' : 'UNCONSUME',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$totalCount ${totalCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF42526E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Groups
          ...groups.entries.map((entry) {
            final key = entry.key;
            final parts = key.split('|');
            final tableName = parts.isNotEmpty ? parts[0] : '-';
            final action = parts.length > 1 ? parts[1] : '-';
            final items = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ConsumeGroup(
                tableName: tableName,
                action: action,
                items: items,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ConsumeGroup extends StatelessWidget {
  final String tableName;
  final String action;
  final List<Map<String, dynamic>> items;

  const _ConsumeGroup({
    required this.tableName,
    required this.action,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFDFE1E6)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.table_chart_outlined,
                size: 14,
                color: Color(0xFF6B778C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tableName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172B4D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFDFE1E6)),
                ),
                child: Text(
                  action,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B778C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B778C),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Items
        ...items.map((row) => _ConsumeRowTile(row: row)).toList(),
      ],
    );
  }
}

class _ConsumeRowTile extends StatelessWidget {
  final Map<String, dynamic> row;

  const _ConsumeRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final noProduksi = pickS(row, [
      'NoProduksi',
      'NoCrusherProduksi',
      'NoPacking',
      'NoBJSortir',
      'NoBongkarSusun'
    ]);
    final noSak = row['NoSak']?.toString();
    final noPartial = row['NoBrokerPartial']?.toString();
    final noFurnitureWip = row['NoFurnitureWIP']?.toString();
    final noFurnitureWipPartial = row['NoFurnitureWIPPartial']?.toString();

    final leftTitle = noProduksi ?? noFurnitureWip ?? '-';
    final rightTitle = (noFurnitureWipPartial != null &&
        noFurnitureWipPartial.isNotEmpty)
        ? noFurnitureWipPartial
        : (noPartial != null && noPartial.isNotEmpty)
        ? noPartial
        : (noSak != null ? 'Sak $noSak' : '');

    final oldPcs = asInt(row['OldPcs']);
    final newPcs = asInt(row['NewPcs']);
    final oldBerat = pickN(row, ['OldBerat'])?.toString();
    final newBerat = pickN(row, ['NewBerat'])?.toString();
    final pcs = asInt(row['Pcs']);
    final berat = row['Berat']?.toString();

    final subtitleParts = <String>[];

    final hasOldNewPcs = (oldPcs != null || newPcs != null);
    if (hasOldNewPcs && oldPcs != newPcs) {
      subtitleParts.add('Pcs: ${oldPcs ?? '-'} → ${newPcs ?? '-'}');
    } else if (pcs != null) {
      subtitleParts.add('Pcs: $pcs');
    }

    final hasOldNewBerat = (oldBerat != null || newBerat != null);
    if (hasOldNewBerat && oldBerat != newBerat) {
      subtitleParts.add('Berat: ${oldBerat ?? '-'} → ${newBerat ?? '-'}');
    } else if (berat != null && berat.isNotEmpty) {
      subtitleParts.add('Berat: $berat kg');
    }

    // for (final k in ['NoBroker', 'NoBahanBaku', 'NoPallet', 'NoBBPartial']) {
    //   if (row[k] != null) subtitleParts.add('$k: ${row[k]}');
    // }

    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFEBECF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: Color(0xFF6B778C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        leftTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                    ),
                    if (rightTitle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEEBFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          rightTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0747A6),
                          ),
                        ),
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B778C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================
// Header Changes Section
// =============================
class _HeaderChangesSection extends StatelessWidget {
  final AuditSession session;

  const _HeaderChangesSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final allKeys = <String>{
      ...session.oldValues.keys,
      ...session.newValues.keys,
    };

    if (allKeys.isEmpty) {
      return CardContainer(
        child: const Text(
          'No header changes.',
          style: TextStyle(
            color: Color(0xFF6B778C),
            fontSize: 14,
          ),
        ),
      );
    }

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allKeys.map((key) {
          final oldValue = session.oldValues[key]?.toString() ?? '-';
          final newValue = session.newValues[key]?.toString() ?? '-';
          final hasChanged = oldValue != newValue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _HeaderChangeRow(
              fieldName: key,
              oldValue: oldValue,
              newValue: newValue,
              hasChanged: hasChanged,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeaderChangeRow extends StatelessWidget {
  final String fieldName;
  final String oldValue;
  final String newValue;
  final bool hasChanged;

  const _HeaderChangeRow({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.hasChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field name
        Row(
          children: [
            if (hasChanged)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF991F),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              fieldName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF42526E),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Before/After
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasChanged
                      ? const Color(0xFFFFEBEB)
                      : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: hasChanged
                        ? const Color(0xFFFFBDAD)
                        : const Color(0xFFDFE1E6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Before',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B778C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldValue,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasChanged
                            ? const Color(0xFFBF2600)
                            : const Color(0xFF172B4D),
                        decoration: hasChanged
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: hasChanged
                    ? const Color(0xFF0052CC)
                    : const Color(0xFFA5ADBA),
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasChanged
                      ? const Color(0xFFE3FCEF)
                      : const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: hasChanged
                        ? const Color(0xFF79F2C0)
                        : const Color(0xFFDFE1E6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'After',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B778C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newValue,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasChanged ? FontWeight.w600 : FontWeight.w400,
                        color: hasChanged
                            ? const Color(0xFF006644)
                            : const Color(0xFF172B4D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================
// Details Changes Section
// =============================
class _DetailsChangesSection extends StatelessWidget {
  final AuditSession session;

  const _DetailsChangesSection({required this.session});

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

            // Details list
            ...comparisonData.map((comparison) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DetailChangeRow(comparison: comparison),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  List<_DetailComparison> _buildComparisonData(
      List<Map<String, dynamic>> oldList,
      List<Map<String, dynamic>> newList,
      ) {
    final comparisons = <_DetailComparison>[];

    final oldMap = <int, Map<String, dynamic>>{
      for (var item in oldList)
        if (item['NoSak'] != null) item['NoSak'] as int: item
    };

    final newMap = <int, Map<String, dynamic>>{
      for (var item in newList)
        if (item['NoSak'] != null) item['NoSak'] as int: item
    };

    final allNoSak = <int>{...oldMap.keys, ...newMap.keys}.toList()..sort();

    for (final noSak in allNoSak) {
      final oldItem = oldMap[noSak];
      final newItem = newMap[noSak];

      String status;
      if (oldItem != null && newItem == null) {
        status = 'DELETED';
      } else if (oldItem == null && newItem != null) {
        status = 'ADDED';
      } else if (_itemsAreDifferent(oldItem, newItem)) {
        status = 'MODIFIED';
      } else {
        status = 'UNCHANGED';
      }

      comparisons.add(_DetailComparison(
        noSak: noSak,
        oldItem: oldItem,
        newItem: newItem,
        status: status,
      ));
    }

    return comparisons;
  }

  bool _itemsAreDifferent(
      Map<String, dynamic>? oldItem, Map<String, dynamic>? newItem) {
    if (oldItem == null || newItem == null) return true;
    return oldItem['Berat'] != newItem['Berat'] ||
        oldItem['IsPartial'] != newItem['IsPartial'] ||
        oldItem['DateUsage'] != newItem['DateUsage'];
  }
}

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

class _DetailItemDisplay extends StatelessWidget {
  final String label;
  final Map<String, dynamic> item;

  const _DetailItemDisplay({
    required this.label,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (item.containsKey('Berat')) {
      parts.add('${item['Berat']} kg');
    }
    if (item.containsKey('IsPartial') && item['IsPartial'] == true) {
      parts.add('Partial');
    }
    if (item.containsKey('DateUsage') && item['DateUsage'] != null) {
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF172B4D),
          ),
        ),
      ],
    );
  }
}

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

// =============================
// Output Changes Section
// =============================
class _OutputChangesSection extends StatelessWidget {
  final AuditSession session;

  const _OutputChangesSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.outputDisplayLabel ?? 'Output',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF42526E),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDEEBFF),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF4C9AFF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF0052CC),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.outputDisplayValue ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0747A6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================
// Raw Data Section
// =============================
class _RawDataSection extends StatefulWidget {
  final AuditSession session;

  const _RawDataSection({required this.session});

  @override
  State<_RawDataSection> createState() => _RawDataSectionState();
}

class _RawDataSectionState extends State<_RawDataSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                const Icon(
                  Icons.code,
                  size: 16,
                  color: Color(0xFF42526E),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Raw JSON Data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: const Color(0xFF6B778C),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            if (widget.session.headerOld != null)
              JsonViewer(title: 'Header (Old)', jsonString: widget.session.headerOld!),
            if (widget.session.headerNew != null)
              JsonViewer(title: 'Header (New)', jsonString: widget.session.headerNew!),
            if (widget.session.detailsOldJson != null)
              JsonViewer(title: 'Details (Old)', jsonString: widget.session.detailsOldJson!),
            if (widget.session.detailsNewJson != null)
              JsonViewer(title: 'Details (New)', jsonString: widget.session.detailsNewJson!),
            if (widget.session.consumeJson != null)
              JsonViewer(title: 'Consume Data', jsonString: widget.session.consumeJson!),
            if (widget.session.unconsumeJson != null)
              JsonViewer(title: 'Unconsume Data', jsonString: widget.session.unconsumeJson!),
            if (widget.session.outputChanges != null)
              JsonViewer(title: 'Output Changes', jsonString: widget.session.outputChanges!),
          ],
        ],
      ),
    );
  }
}