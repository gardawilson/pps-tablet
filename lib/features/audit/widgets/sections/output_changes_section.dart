import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';
import '../../model/audit_session_model.dart';

class OutputChangesSection extends StatelessWidget {
  final AuditSession session;

  const OutputChangesSection({super.key, required this.session});

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
