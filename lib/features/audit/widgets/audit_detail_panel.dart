import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/card_container.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/info_row.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/simple_divider.dart';

import '../view_model/audit_view_model.dart';
import '../model/audit_session_model.dart';

import 'components/action_lozenge.dart';
import 'sections/consume_unconsume_section.dart';
import 'sections/produce_unproduce_section.dart';
import 'sections/header_changes_section.dart';
import 'sections/details_changes_section.dart';
import 'sections/output_changes_section.dart';
import 'sections/raw_data_section.dart';

class AuditDetailPanel extends StatelessWidget {
  const AuditDetailPanel({super.key});

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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: vm.selectedSession != null
                    ? _SessionDetail(session: vm.selectedSession!)
                    : const EmptyState(
                        icon: Icons.list_alt_outlined,
                        title: 'No activity selected',
                        subtitle:
                            'Select an activity from the list to view details',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===================================================================
// Session Detail
// ===================================================================
class _SessionDetail extends StatelessWidget {
  final AuditSession session;

  const _SessionDetail({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM dd, yyyy');
    final timeFmt = DateFormat('HH:mm:ss');

    final start = DateTime.tryParse(session.startTime);
    final end = DateTime.tryParse(session.endTime);

    final hasHeaderChanges =
        session.oldValues.isNotEmpty || session.newValues.isNotEmpty;

    final hasDetailsChanges =
        session.detailsOldList != null || session.detailsNewList != null;

    final hasConsumeBlock =
        session.consumeUnifiedItems != null &&
        session.consumeUnifiedItems!.isNotEmpty;

    final hasProduceBlock =
        session.produceUnifiedItems != null &&
        session.produceUnifiedItems!.isNotEmpty;

    final hasRaw =
        session.headerOld != null ||
        session.headerNew != null ||
        session.detailsOldJson != null ||
        session.detailsNewJson != null ||
        session.consumeJson != null ||
        session.unconsumeJson != null ||
        session.produceJson != null ||
        session.unproduceJson != null ||
        session.outputChanges != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =============================================================
          // Overview Card
          // =============================================================
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ActionLozenge(action: session.sessionAction),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        session.documentNo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const SimpleDivider(),
                const SizedBox(height: 20),

                InfoRow(
                  icon: Icons.person_outline,
                  label: 'User',
                  value: session.actor,
                ),
                const SizedBox(height: 12),

                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: start != null ? dateFmt.format(start) : '-',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'Start',
                        value: start != null ? timeFmt.format(start) : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'End',
                        value: end != null ? timeFmt.format(end) : '-',
                      ),
                    ),
                  ],
                ),

                if (session.requestId != null) ...[
                  const SizedBox(height: 12),
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

          // =============================================================
          // CONSUME / UNCONSUME
          // =============================================================
          if (hasConsumeBlock) ...[
            SectionHeader(
              icon: Icons.input_outlined,
              title: session.isConsume
                  ? 'Material Consumption'
                  : 'Material Unconsumption',
            ),
            const SizedBox(height: 12),
            ConsumeUnconsumeSection(session: session),
            const SizedBox(height: 16),
          ],

          // =============================================================
          // PRODUCE / UNPRODUCE / ADJUST
          // =============================================================
          if (hasProduceBlock) ...[
            SectionHeader(
              icon: Icons.output_outlined,
              title: _productionSectionTitle(session),
            ),
            const SizedBox(height: 12),
            ProduceUnproduceSection(session: session),
            const SizedBox(height: 16),
          ],

          // =============================================================
          // HEADER CHANGES
          // =============================================================
          if (hasHeaderChanges) ...[
            const SectionHeader(
              icon: Icons.edit_note_outlined,
              title: 'Header Modifications',
            ),
            const SizedBox(height: 12),
            HeaderChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // =============================================================
          // DETAIL CHANGES
          // =============================================================
          if (hasDetailsChanges &&
              !session.isConsumeSession &&
              !session.isProduceSession) ...[
            SectionHeader(
              icon: Icons.list_alt_outlined,
              title: 'Detail Line Changes',
              subtitle: session.detailsChangeSummary,
            ),
            const SizedBox(height: 12),
            DetailsChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // =============================================================
          // OUTPUT RELATION (single link)
          // =============================================================
          if (session.outputDisplayValue != null) ...[
            const SectionHeader(icon: Icons.link, title: 'Output Relation'),
            const SizedBox(height: 12),
            OutputChangesSection(session: session),
            const SizedBox(height: 16),
          ],

          // =============================================================
          // RAW DATA
          // =============================================================
          if (hasRaw) RawDataSection(session: session),
        ],
      ),
    );
  }
}

String _productionSectionTitle(AuditSession session) {
  if (session.isAdjust) {
    return 'Production Adjustment';
  }
  if (session.isProduce) {
    return 'Production Output';
  }
  if (session.isUnproduce) {
    return 'Production Rollback';
  }
  return 'Production Activity';
}
