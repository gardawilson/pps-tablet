// lib/features/audit/model/audit_session_model.dart

import 'dart:convert';

import 'audit_config.dart';

class AuditSession {
  // =============================
  // Core session info
  // =============================
  final String startTime;
  final String endTime;
  final String actor;
  final String? requestId;
  final String sessionKey;
  final String documentNo;
  final String sessionAction; // CREATE | UPDATE | DELETE

  // =============================
  // Parsed field values (OLD vs NEW)
  // =============================
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;

  // =============================
  // Raw JSON strings
  // =============================
  final String? headerInserted;
  final String? headerOld;
  final String? headerNew;
  final String? headerDeleted;
  final String? detailsOldJson;
  final String? detailsNewJson;

  // =============================
  // Single aggregated output field
  // =============================
  final String? outputChanges;

  // =============================
  // Constructor
  // =============================
  const AuditSession({
    required this.startTime,
    required this.endTime,
    required this.actor,
    this.requestId,
    required this.sessionKey,
    required this.documentNo,
    required this.sessionAction,
    this.oldValues = const {},
    this.newValues = const {},
    this.headerInserted,
    this.headerOld,
    this.headerNew,
    this.headerDeleted,
    this.detailsOldJson,
    this.detailsNewJson,
    this.outputChanges,
  });

  // =============================
  // Helper methods - Type conversion
  // =============================
  static String _s(dynamic v) => (v ?? '').toString();

  static String? _sN(dynamic v) {
    if (v == null) return null;
    final str = v.toString();
    return str.isEmpty ? null : str;
  }

  static int? _iN(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _dN(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // =============================
  // Parse Details JSON
  // =============================
  List<Map<String, dynamic>>? get detailsOldList {
    if (detailsOldJson == null || detailsOldJson!.isEmpty) return null;
    try {
      final decoded = json.decode(detailsOldJson!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('⚠️ Failed to parse detailsOldJson: $e');
    }
    return null;
  }

  List<Map<String, dynamic>>? get detailsNewList {
    if (detailsNewJson == null || detailsNewJson!.isEmpty) return null;
    try {
      final decoded = json.decode(detailsNewJson!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('⚠️ Failed to parse detailsNewJson: $e');
    }
    return null;
  }

  // =============================
  // Compare Details (for summary)
  // =============================
  String get detailsChangeSummary {
    final oldCount = detailsOldList?.length ?? 0;
    final newCount = detailsNewList?.length ?? 0;

    if (oldCount == 0 && newCount == 0) return 'No changes';
    if (oldCount == 0) return 'Added $newCount item(s)';
    if (newCount == 0) return 'Removed $oldCount item(s)';

    final diff = newCount - oldCount;
    if (diff == 0) return 'Modified (same count)';
    if (diff > 0) return 'Added ${diff.abs()} item(s)';
    return 'Removed ${diff.abs()} item(s)';
  }

  // =============================
  // ✅ REVISED: Parse Output Changes (single object, not array)
  // =============================
  Map<String, dynamic>? get outputData {
    if (outputChanges == null || outputChanges!.isEmpty) return null;
    try {
      final decoded = json.decode(outputChanges!);
      if (decoded is Map) {
        return decoded as Map<String, dynamic>;
      }
    } catch (e) {
      print('⚠️ Failed to parse outputChanges: $e');
    }
    return null;
  }

  // =============================
  // ✅ NEW: Convenience getters for output fields
  // =============================
  String? get outputTableName => outputData?['TableName'] as String?;
  String? get outputDisplayLabel => outputData?['DisplayLabel'] as String?;
  String? get outputDisplayValue => outputData?['DisplayValue'] as String?;
  String? get outputAction => outputData?['Action'] as String?;

  // =============================
  // ✅ REMOVED: Old methods (no longer needed)
  // =============================
  // List<Map<String, dynamic>>? get outputChangesList { ... }
  // Map<String, List<Map<String, dynamic>>> get outputsByTable { ... }
  // String getOutputTableLabel(String tableName) { ... }

  // =============================
  // Enhanced fromJson with Scalar Support
  // =============================
  factory AuditSession.fromJson(
      Map<String, dynamic> json, {
        List<AuditFieldConfig>? fieldConfigs,
      }) {
    final oldValues = <String, dynamic>{};
    final newValues = <String, dynamic>{};

    if (fieldConfigs != null) {
      for (final config in fieldConfigs) {
        if (config.isRelational) {
          // ✅ Handle relational fields (ID + Name pairs)
          final oldIdKey = 'Old${config.idField}';
          final oldNameKey = 'Old${config.nameField}';

          if (json.containsKey(oldIdKey)) {
            oldValues[config.idField] = _iN(json[oldIdKey]);
          }
          if (config.nameField != null && json.containsKey(oldNameKey)) {
            oldValues[config.nameField!] = _sN(json[oldNameKey]);
          }

          final newIdKey = 'New${config.idField}';
          final newNameKey = 'New${config.nameField}';

          if (json.containsKey(newIdKey)) {
            newValues[config.idField] = _iN(json[newIdKey]);
          }
          if (config.nameField != null && json.containsKey(newNameKey)) {
            newValues[config.nameField!] = _sN(json[newNameKey]);
          }
        } else if (config.isScalar) {
          // ✅ Handle scalar fields (single values)
          final oldKey = 'Old${config.idField}';
          final newKey = 'New${config.idField}';

          if (json.containsKey(oldKey)) {
            final value = json[oldKey];
            // Try to preserve type (number, string, etc)
            if (value is num) {
              oldValues[config.idField] = value is double ? value : _dN(value);
            } else {
              oldValues[config.idField] = _sN(value);
            }
          }

          if (json.containsKey(newKey)) {
            final value = json[newKey];
            // Try to preserve type (number, string, etc)
            if (value is num) {
              newValues[config.idField] = value is double ? value : _dN(value);
            } else {
              newValues[config.idField] = _sN(value);
            }
          }
        }
      }

      // Status handling (special case)
      if (json.containsKey('OldStatusText')) {
        oldValues['StatusText'] = _sN(json['OldStatusText']);
      }
      if (json.containsKey('NewStatusText')) {
        newValues['StatusText'] = _sN(json['NewStatusText']);
      }
    }

    return AuditSession(
      startTime: _s(json['StartTime']),
      endTime: _s(json['EndTime']),
      actor: _s(json['Actor']),
      requestId: _sN(json['RequestId']),
      sessionKey: _s(json['SessionKey']),
      documentNo: _s(json['DocumentNo']),
      sessionAction: _s(json['SessionAction']),
      oldValues: oldValues,
      newValues: newValues,
      headerInserted: _sN(json['HeaderInserted']),
      headerOld: _sN(json['HeaderOld']),
      headerNew: _sN(json['HeaderNew']),
      headerDeleted: _sN(json['HeaderDeleted']),
      detailsOldJson: _sN(json['DetailsOldJson']),
      detailsNewJson: _sN(json['DetailsNewJson']),
      outputChanges: _sN(json['OutputChanges']),
    );
  }

  // =============================
  // Value getters
  // =============================
  T? getOldValue<T>(String key) => oldValues[key] as T?;
  T? getNewValue<T>(String key) => newValues[key] as T?;

  /// Get current value (prefer NEW over OLD)
  T? getCurrentValue<T>(String key) =>
      (newValues[key] ?? oldValues[key]) as T?;

  /// Check if field changed
  bool hasFieldChanged(String key) {
    return oldValues[key] != newValues[key];
  }

  /// Get all changed field keys
  Set<String> get changedFields {
    final allKeys = <String>{
      ...oldValues.keys,
      ...newValues.keys,
    };
    return allKeys.where((key) => hasFieldChanged(key)).toSet();
  }

  /// Count of changed fields
  int get changedFieldsCount => changedFields.length;
}