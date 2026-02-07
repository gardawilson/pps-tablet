import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';
import 'package:pps_tablet/common/widgets/json_viewer.dart';
import 'package:pps_tablet/features/audit/model/audit_session_model.dart';

class RawDataSection extends StatefulWidget {
  final AuditSession session;

  const RawDataSection({super.key, required this.session});

  @override
  State<RawDataSection> createState() => _RawDataSectionState();
}

class _RawDataSectionState extends State<RawDataSection> {
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
                const Icon(Icons.code, size: 16, color: Color(0xFF42526E)),
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
          if (_isExpanded) ..._buildJsonBlocks(),
        ],
      ),
    );
  }

  List<Widget> _buildJsonBlocks() {
    final s = widget.session;

    return [
      const SizedBox(height: 16),
      if (s.headerOld != null)
        JsonViewer(title: 'Header (Old)', jsonString: s.headerOld!),
      if (s.headerNew != null)
        JsonViewer(title: 'Header (New)', jsonString: s.headerNew!),
      if (s.detailsOldJson != null)
        JsonViewer(title: 'Details (Old)', jsonString: s.detailsOldJson!),
      if (s.detailsNewJson != null)
        JsonViewer(title: 'Details (New)', jsonString: s.detailsNewJson!),
      if (s.consumeJson != null)
        JsonViewer(title: 'Consume Data', jsonString: s.consumeJson!),
      if (s.unconsumeJson != null)
        JsonViewer(title: 'Unconsume Data', jsonString: s.unconsumeJson!),
      if (s.produceJson != null)
        JsonViewer(title: 'Produce Data', jsonString: s.produceJson!),
      if (s.unproduceJson != null)
        JsonViewer(title: 'Unproduce Data', jsonString: s.unproduceJson!),
      if (s.outputChanges != null)
        JsonViewer(title: 'Output Changes', jsonString: s.outputChanges!),
    ];
  }
}
