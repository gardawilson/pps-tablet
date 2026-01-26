// lib/features/audit/widgets/audit_detail_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../view_model/audit_view_model.dart';
import '../model/audit_session_model.dart';

class AuditDetailPanel extends StatelessWidget {
  const AuditDetailPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Session Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: vm.selectedSession != null
                  ? _SessionDetail(session: vm.selectedSession!)
                  : _EmptyState(),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Select a session to view details',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetail extends StatelessWidget {
  final AuditSession session;

  const _SessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm:ss');
    final startTime = DateTime.tryParse(session.startTime);
    final endTime = DateTime.tryParse(session.endTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session info card
          _SessionInfoCard(
            session: session,
            dateFormat: dateFormat,
            startTime: startTime,
            endTime: endTime,
          ),

          const SizedBox(height: 16),

          // ✅ Header changes
          if (session.oldValues.isNotEmpty || session.newValues.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.description,
              title: 'Header Changes',
            ),
            const SizedBox(height: 8),
            _HeaderChangesTable(session: session),
            const SizedBox(height: 16),
          ],

          // ✅ Details changes
          if (session.detailsOldList != null ||
              session.detailsNewList != null) ...[
            _SectionHeader(
              icon: Icons.list,
              title: 'Details Changes',
              subtitle: session.detailsChangeSummary,
            ),
            const SizedBox(height: 8),
            _DetailsChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // ✅ Output changes (REVISED - using outputDisplayValue)
          if (session.outputDisplayValue != null) ...[
            _SectionHeader(
              icon: Icons.link,
              title: 'Output Relation',
            ),
            const SizedBox(height: 8),
            _OutputChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // Raw JSON section (collapsible)
          if (session.headerOld != null ||
              session.headerNew != null ||
              session.detailsOldJson != null ||
              session.detailsNewJson != null ||
              session.outputChanges != null)
            _RawDataSection(session: session),
        ],
      ),
    );
  }
}

// =============================
// Section Header Widget
// =============================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================
// Session Info Card
// =============================
class _SessionInfoCard extends StatelessWidget {
  final AuditSession session;
  final DateFormat dateFormat;
  final DateTime? startTime;
  final DateTime? endTime;

  const _SessionInfoCard({
    required this.session,
    required this.dateFormat,
    this.startTime,
    this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Document Number',
              session.documentNo,
              Icons.description,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Action',
              session.sessionAction,
              Icons.settings,
              valueColor: _getActionColor(session.sessionAction),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Actor',
              session.actor,
              Icons.person,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Start Time',
              startTime != null
                  ? dateFormat.format(startTime!)
                  : session.startTime,
              Icons.access_time,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'End Time',
              endTime != null ? dateFormat.format(endTime!) : session.endTime,
              Icons.access_time_filled,
            ),
            if (session.requestId != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                'Request ID',
                session.requestId!,
                Icons.fingerprint,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return Colors.green;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

// =============================
// Header Changes Table
// =============================
class _HeaderChangesTable extends StatelessWidget {
  final AuditSession session;

  const _HeaderChangesTable({required this.session});

  @override
  Widget build(BuildContext context) {
    final allKeys = <String>{
      ...session.oldValues.keys,
      ...session.newValues.keys,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(3),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Field',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Before',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'After',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Data rows
            ...allKeys.map((key) {
              final oldValue = session.oldValues[key]?.toString() ?? '-';
              final newValue = session.newValues[key]?.toString() ?? '-';
              final hasChanged = oldValue != newValue;

              return TableRow(
                decoration: hasChanged
                    ? BoxDecoration(color: Colors.yellow[50])
                    : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (hasChanged)
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.orange,
                          ),
                        if (hasChanged) const SizedBox(width: 8),
                        Expanded(child: Text(key)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      oldValue,
                      style: TextStyle(
                        decoration: hasChanged
                            ? TextDecoration.lineThrough
                            : null,
                        color: hasChanged ? Colors.grey : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      newValue,
                      style: hasChanged
                          ? const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      )
                          : null,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
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

    // ✅ Build comparison data by NoSak
    final comparisonData = _buildComparisonData(oldList, newList);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Row(
              children: [
                _buildCountBadge('Before', oldList.length, Colors.red),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 12),
                _buildCountBadge('After', newList.length, Colors.green),
              ],
            ),
            const SizedBox(height: 16),

            // Change summary
            _buildChangeSummary(comparisonData),
            const SizedBox(height: 16),

            // Table
            if (comparisonData.isNotEmpty)
              _buildDetailsTable(comparisonData),
          ],
        ),
      ),
    );
  }

  // ✅ Build comparison data structure
  List<_DetailComparison> _buildComparisonData(
      List<Map<String, dynamic>> oldList,
      List<Map<String, dynamic>> newList,
      ) {
    final comparisons = <_DetailComparison>[];

    // Create maps by NoSak for easy lookup
    final oldMap = <int, Map<String, dynamic>>{
      for (var item in oldList)
        if (item['NoSak'] != null) item['NoSak'] as int: item
    };

    final newMap = <int, Map<String, dynamic>>{
      for (var item in newList)
        if (item['NoSak'] != null) item['NoSak'] as int: item
    };

    // Get all unique NoSak values
    final allNoSak = <int>{
      ...oldMap.keys,
      ...newMap.keys,
    }.toList()..sort(); // Convert to List first, then sort

    // Build comparison for each NoSak
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

  // ✅ Check if items are different
  bool _itemsAreDifferent(
      Map<String, dynamic>? oldItem,
      Map<String, dynamic>? newItem,
      ) {
    if (oldItem == null || newItem == null) return true;

    // Compare key fields
    return oldItem['Berat'] != newItem['Berat'] ||
        oldItem['IsPartial'] != newItem['IsPartial'] ||
        oldItem['DateUsage'] != newItem['DateUsage'];
  }

  // ✅ Build change summary
  Widget _buildChangeSummary(List<_DetailComparison> comparisons) {
    final added = comparisons.where((c) => c.status == 'ADDED').length;
    final deleted = comparisons.where((c) => c.status == 'DELETED').length;
    final modified = comparisons.where((c) => c.status == 'MODIFIED').length;
    final unchanged = comparisons.where((c) => c.status == 'UNCHANGED').length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (deleted > 0)
          _buildStatusBadge('Deleted', deleted, Colors.red),
        if (added > 0)
          _buildStatusBadge('Added', added, Colors.green),
        if (modified > 0)
          _buildStatusBadge('Modified', modified, Colors.orange),
        if (unchanged > 0)
          _buildStatusBadge('Unchanged', unchanged, Colors.grey),
      ],
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // ✅ Build table with proper comparison
  Widget _buildDetailsTable(List<_DetailComparison> comparisons) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(3),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Sak#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Before', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('After', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        // Data rows
        ...comparisons.map((comparison) {
          final statusColor = _getStatusColor(comparison.status);
          final oldStr = comparison.oldItem != null
              ? _formatDetailItem(comparison.oldItem!)
              : '-';
          final newStr = comparison.newItem != null
              ? _formatDetailItem(comparison.newItem!)
              : '-';

          return TableRow(
            decoration: comparison.status != 'UNCHANGED'
                ? BoxDecoration(color: statusColor.withOpacity(0.1))
                : null,
            children: [
              // Sak number
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${comparison.noSak}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // Status badge
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    comparison.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Before
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  oldStr,
                  style: TextStyle(
                    decoration: comparison.status == 'DELETED' ||
                        comparison.status == 'MODIFIED'
                        ? TextDecoration.lineThrough
                        : null,
                    color: comparison.status == 'DELETED'
                        ? Colors.grey
                        : null,
                    fontSize: 12,
                  ),
                ),
              ),

              // After
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  newStr,
                  style: TextStyle(
                    fontWeight: comparison.status == 'ADDED' ||
                        comparison.status == 'MODIFIED'
                        ? FontWeight.bold
                        : null,
                    color: comparison.status == 'ADDED'
                        ? Colors.green
                        : comparison.status == 'MODIFIED'
                        ? Colors.blue
                        : null,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELETED':
        return Colors.red;
      case 'ADDED':
        return Colors.green;
      case 'MODIFIED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDetailItem(Map<String, dynamic> item) {
    final parts = <String>[];

    if (item.containsKey('Berat')) {
      parts.add('${item['Berat']}kg');
    }
    if (item.containsKey('IsPartial')) {
      final isPartial = item['IsPartial'];
      if (isPartial == true) {
        parts.add('(Partial)');
      }
    }
    if (item.containsKey('DateUsage') && item['DateUsage'] != null) {
      parts.add('Used: ${item['DateUsage']}');
    }

    return parts.isNotEmpty ? parts.join(' • ') : '-';
  }
}

// ✅ Helper class for comparison
class _DetailComparison {
  final int noSak;
  final Map<String, dynamic>? oldItem;
  final Map<String, dynamic>? newItem;
  final String status; // DELETED | ADDED | MODIFIED | UNCHANGED

  _DetailComparison({
    required this.noSak,
    this.oldItem,
    this.newItem,
    required this.status,
  });
}
// =============================
// ✅ REVISED: Output Changes Section (Simple Display)
// =============================
class _OutputChangesSection extends StatelessWidget {
  final AuditSession session;

  const _OutputChangesSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label
            Row(
              children: [
                Icon(Icons.link, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  session.outputDisplayLabel ?? 'Output',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Display Value
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.outputDisplayValue ?? '-',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Raw JSON Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.session.headerOld != null)
                    _buildJsonBlock('Header (Old)', widget.session.headerOld!),
                  if (widget.session.headerNew != null)
                    _buildJsonBlock('Header (New)', widget.session.headerNew!),
                  if (widget.session.detailsOldJson != null)
                    _buildJsonBlock(
                        'Details (Old)', widget.session.detailsOldJson!),
                  if (widget.session.detailsNewJson != null)
                    _buildJsonBlock(
                        'Details (New)', widget.session.detailsNewJson!),
                  if (widget.session.outputChanges != null)
                    _buildJsonBlock(
                        'Output Changes', widget.session.outputChanges!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJsonBlock(String title, String jsonString) {
    String formatted;
    try {
      final decoded = json.decode(jsonString);
      formatted = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      formatted = jsonString;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(
            formatted,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}