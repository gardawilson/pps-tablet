// lib/features/audit/widgets/audit_session_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pps_tablet/features/audit/widgets/components/action_lozenge.dart';

import '../model/audit_session_model.dart';

class AuditSessionCard extends StatelessWidget {
  final AuditSession session;
  final bool isSelected;
  final VoidCallback onTap;

  const AuditSessionCard({
    super.key,
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final startTime = DateTime.tryParse(session.startTime);
    final changedFieldsCount = _getChangedFieldsCount(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFDEEBFF) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isSelected ? const Color(0xFF0052CC) : Colors.transparent,
            width: 3,
          ),
          bottom: BorderSide(color: const Color(0xFFDFE1E6), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFFDEEBFF).withOpacity(0.3),
          highlightColor: const Color(0xFFDEEBFF).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Action type badge (Atlassian style lozenge)
                ActionLozenge(action: session.sessionAction),

                const SizedBox(width: 12),

                // Metadata row
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      // Date
                      _MetadataItem(
                        icon: Icons.calendar_today_outlined,
                        text: startTime != null
                            ? dateFormat.format(startTime)
                            : '-',
                      ),

                      const SizedBox(width: 16),

                      // Time
                      _MetadataItem(
                        icon: Icons.schedule_outlined,
                        text: startTime != null
                            ? timeFormat.format(startTime)
                            : '-',
                      ),

                      const SizedBox(width: 16),

                      // Actor (with avatar-like icon)
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getAvatarColor(session.actor),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons
                                      .person_rounded, // atau Icons.person_outline_rounded
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                session.actor,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF42526E),
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Chevron indicator
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF0052CC)
                      : const Color(0xFFA5ADBA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6554C0), // Purple
      const Color(0xFF00B8D9), // Cyan
      const Color(0xFF36B37E), // Green
      const Color(0xFFFF5630), // Red
      const Color(0xFF0052CC), // Blue
      const Color(0xFFFF991F), // Orange
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  int _getChangedFieldsCount(AuditSession session) {
    final allKeys = <String>{
      ...session.oldValues.keys,
      ...session.newValues.keys,
    };

    return allKeys.where((key) {
      return session.oldValues[key] != session.newValues[key];
    }).length;
  }
}

// =============================
// Metadata Item Component
// =============================
class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B778C)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B778C),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
