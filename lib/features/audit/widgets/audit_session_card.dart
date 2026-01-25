// lib/features/audit/widgets/audit_session_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/audit_session_model.dart';

class AuditSessionCard extends StatelessWidget {
  final AuditSession session;
  final bool isSelected;
  final VoidCallback onTap;

  const AuditSessionCard({
    Key? key,
    required this.session,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');
    final startTime = DateTime.tryParse(session.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: Colors.blue[300]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action badge + Document
              Row(
                children: [
                  _buildActionBadge(session.sessionAction),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.documentNo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Timestamp
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    startTime != null
                        ? dateFormat.format(startTime)
                        : session.startTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Actor
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    session.actor,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Change indicator
              if (session.oldValues.isNotEmpty || session.newValues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${_getChangedFieldsCount(session)} field(s) changed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    Color color;
    IconData icon;

    switch (action.toUpperCase()) {
      case 'CREATE':
        color = Colors.green;
        icon = Icons.add_circle;
        break;
      case 'DELETE':
        color = Colors.red;
        icon = Icons.delete;
        break;
      default:
        color = Colors.blue;
        icon = Icons.edit;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            action.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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
