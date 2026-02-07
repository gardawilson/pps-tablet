import 'package:flutter/material.dart';
import 'package:pps_tablet/common/widgets/card_container.dart';
import 'package:pps_tablet/common/widgets/empty_state.dart';
import 'package:pps_tablet/features/audit/model/audit_session_model.dart';
import 'package:pps_tablet/features/audit/model/audit_config.dart';
import 'package:provider/provider.dart';
import '../../view_model/audit_view_model.dart';

class HeaderChangesSection extends StatelessWidget {
  final AuditSession session;

  const HeaderChangesSection({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    // ✅ Get config from ViewModel
    final viewModel = context.watch<AuditViewModel>();
    final configs = viewModel.currentConfig?.fields ?? [];

    if (configs.isEmpty) {
      // Fallback jika tidak ada config - tampilkan raw
      return _buildRawHeaders();
    }

    // Build changes based on config
    final changes = _buildConfiguredChanges(configs);

    if (changes.isEmpty) {
      return CardContainer(
        child: EmptyState(
          icon: Icons.edit_note,
          iconSize: 60,
          title: 'No header changes',
          subtitle: null,
        ),
      );
    }

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: changes,
      ),
    );
  }

  /// Build changes menggunakan field configs
  List<Widget> _buildConfiguredChanges(List<AuditFieldConfig> configs) {
    final changes = <Widget>[];

    for (final config in configs) {
      // Get old/new values using session's getters
      final oldValue = _getOldValue(config);
      final newValue = _getNewValue(config);

      // Skip jika both null/empty
      if (_isEmpty(oldValue) && _isEmpty(newValue)) {
        continue;
      }

      // Determine if changed
      final hasChanged = oldValue != newValue;

      changes.add(
        Padding(
          padding: EdgeInsets.only(bottom: changes.isEmpty ? 0 : 16),
          child: _HeaderChangeRow(
            fieldName: config.displayLabel, // ✅ Display name dari config
            oldValue: oldValue ?? '-',
            newValue: newValue ?? '-',
            hasChanged: hasChanged,
          ),
        ),
      );
    }

    return changes;
  }

  /// Get old value based on field type
  String? _getOldValue(AuditFieldConfig config) {
    if (config.isRelational && config.nameField != null) {
      // Prefer name field over ID field
      return session.getOldValue<String>(config.nameField!) ??
          session.getOldValue<int>(config.idField)?.toString();
    }
    // Scalar field atau relational tanpa name field
    final value = session.oldValues[config.idField];
    return value?.toString();
  }

  /// Get new value based on field type
  String? _getNewValue(AuditFieldConfig config) {
    if (config.isRelational && config.nameField != null) {
      // Prefer name field over ID field
      return session.getNewValue<String>(config.nameField!) ??
          session.getNewValue<int>(config.idField)?.toString();
    }
    // Scalar field atau relational tanpa name field
    final value = session.newValues[config.idField];
    return value?.toString();
  }

  /// Check if value is empty
  bool _isEmpty(String? value) {
    return value == null || value.isEmpty || value == '-';
  }

  /// Fallback untuk raw display (tanpa config)
  Widget _buildRawHeaders() {
    final allKeys = <String>{
      ...session.oldValues.keys,
      ...session.newValues.keys,
    };

    if (allKeys.isEmpty) {
      return CardContainer(
        child: EmptyState(
          icon: Icons.edit_note,
          iconSize: 60,
          title: 'No header changes',
          subtitle: null,
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
              fieldName: key, // Raw key name
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

// =============================
// Header Change Row
// =============================
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

        // Before / After
        Row(
          children: [
            Expanded(
              child: _ValueBox(
                label: 'Before',
                value: oldValue,
                isChanged: hasChanged,
                isBefore: true,
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
              child: _ValueBox(
                label: 'After',
                value: newValue,
                isChanged: hasChanged,
                isBefore: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================
// Value Box
// =============================
class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isChanged;
  final bool isBefore;

  const _ValueBox({
    required this.label,
    required this.value,
    required this.isChanged,
    required this.isBefore,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isChanged
        ? (isBefore ? const Color(0xFFFFEBEB) : const Color(0xFFE3FCEF))
        : const Color(0xFFF4F5F7);

    final borderColor = isChanged
        ? (isBefore ? const Color(0xFFFFBDAD) : const Color(0xFF79F2C0))
        : const Color(0xFFDFE1E6);

    final textColor = isChanged
        ? (isBefore ? const Color(0xFFBF2600) : const Color(0xFF006644))
        : const Color(0xFF172B4D);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: borderColor),
      ),
      child: Column(
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
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isChanged && !isBefore
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: textColor,
              decoration: isChanged && isBefore
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
