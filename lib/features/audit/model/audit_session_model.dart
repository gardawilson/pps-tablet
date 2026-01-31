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

  /// CREATE | UPDATE | DELETE | CONSUME | UNCONSUME
  final String sessionAction;

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

  // ✅ NEW: consume/unconsume (outer event list json)
  final String? consumeJson;
  final String? unconsumeJson;

  // =============================
  // Single aggregated output field
  // =============================
  final String? outputChanges;

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
    this.consumeJson,
    this.unconsumeJson,
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
  // Action helpers
  // =============================
  bool get isCreate => sessionAction.toUpperCase() == 'CREATE';
  bool get isDelete => sessionAction.toUpperCase() == 'DELETE';

  /// ✅ Updated for new format: sessionAction = CONSUME / UNCONSUME
  bool get isConsume => sessionAction.toUpperCase() == 'CONSUME';
  bool get isUnconsume => sessionAction.toUpperCase() == 'UNCONSUME';
  bool get isConsumeSession => isConsume || isUnconsume;

  // =============================
  // Parse JSON helpers
  // =============================
  List<Map<String, dynamic>>? _parseListJson(String? raw, String logName) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        // ensure map
        return decoded.map((e) => (e as Map).cast<String, dynamic>()).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Failed to parse $logName: $e');
    }
    return null;
  }

  Map<String, dynamic>? _parseMapJson(String? raw, String logName) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Failed to parse $logName: $e');
    }
    return null;
  }

  // =============================
  // Details JSON
  // =============================
  List<Map<String, dynamic>>? get detailsOldList =>
      _parseListJson(detailsOldJson, 'detailsOldJson');

  List<Map<String, dynamic>>? get detailsNewList =>
      _parseListJson(detailsNewJson, 'detailsNewJson');

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
  // ✅ Consume / Unconsume (NEW FORMAT)
  // Outer list = events
  // Each event has TableName, Action, OldData/NewData (string JSON)
  // =============================

  /// Outer events list
  List<Map<String, dynamic>>? get consumeEvents =>
      _parseListJson(consumeJson, 'consumeJson');

  List<Map<String, dynamic>>? get unconsumeEvents =>
      _parseListJson(unconsumeJson, 'unconsumeJson');

  /// Prefer consume else unconsume (for UI)
  List<Map<String, dynamic>>? get consumeUnifiedEvents =>
      consumeEvents ?? unconsumeEvents;

  /// Parse the event payload string (OldData/NewData) into list of items
  List<Map<String, dynamic>> _parseEventItems(Map<String, dynamic> event) {
    // On UNCONSUME usually OldData has the removed relation; on CONSUME usually NewData has the inserted relation.
    final raw = (event['OldData'] ?? event['NewData'])?.toString();
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => (e as Map).cast<String, dynamic>()).toList();
      }
      if (decoded is Map) {
        return [decoded.cast<String, dynamic>()];
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Failed to parse consume event item list: $e');
    }

    return [];
  }

  /// Flattened items for quick rendering
  List<Map<String, dynamic>>? get consumeItems {
    final events = consumeEvents;
    if (events == null || events.isEmpty) return null;

    final out = <Map<String, dynamic>>[];
    for (final ev in events) {
      final tableName = ev['TableName']?.toString();
      final action = ev['Action']?.toString();

      final items = _parseEventItems(ev);
      for (final it in items) {
        // enrich for UI
        out.add({
          ...it,
          if (tableName != null) '_TableName': tableName,
          if (action != null) '_Action': action,
        });
      }
    }
    return out.isEmpty ? null : out;
  }

  List<Map<String, dynamic>>? get unconsumeItems {
    final events = unconsumeEvents;
    if (events == null || events.isEmpty) return null;

    final out = <Map<String, dynamic>>[];
    for (final ev in events) {
      final tableName = ev['TableName']?.toString();
      final action = ev['Action']?.toString();

      final items = _parseEventItems(ev);
      for (final it in items) {
        out.add({
          ...it,
          if (tableName != null) '_TableName': tableName,
          if (action != null) '_Action': action,
        });
      }
    }
    return out.isEmpty ? null : out;
  }

  /// ✅ Best single list for UI (consume or unconsume)
  List<Map<String, dynamic>>? get consumeUnifiedItems =>
      consumeItems ?? unconsumeItems;

  /// Grouping for UI: key = "TableName|Action"
  Map<String, List<Map<String, dynamic>>> get consumeGroups {
    final items = consumeItems ?? const <Map<String, dynamic>>[];
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final it in items) {
      final t = it['_TableName']?.toString() ?? '-';
      final a = it['_Action']?.toString() ?? '-';
      final key = '$t|$a';
      (groups[key] ??= []).add(it);
    }
    return groups;
  }

  Map<String, List<Map<String, dynamic>>> get unconsumeGroups {
    final items = unconsumeItems ?? const <Map<String, dynamic>>[];
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final it in items) {
      final t = it['_TableName']?.toString() ?? '-';
      final a = it['_Action']?.toString() ?? '-';
      final key = '$t|$a';
      (groups[key] ??= []).add(it);
    }
    return groups;
  }

  // =============================
  // Output Changes (single object)
  // =============================
  Map<String, dynamic>? get outputData =>
      _parseMapJson(outputChanges, 'outputChanges');

  String? get outputTableName => outputData?['TableName'] as String?;
  String? get outputDisplayLabel => outputData?['DisplayLabel'] as String?;
  String? get outputDisplayValue => outputData?['DisplayValue'] as String?;
  String? get outputAction => outputData?['Action'] as String?;

  // =============================
  // fromJson with Scalar Support
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
          final oldKey = 'Old${config.idField}';
          final newKey = 'New${config.idField}';

          if (json.containsKey(oldKey)) {
            final value = json[oldKey];
            if (value is num) {
              oldValues[config.idField] = value is double ? value : _dN(value);
            } else {
              oldValues[config.idField] = _sN(value);
            }
          }

          if (json.containsKey(newKey)) {
            final value = json[newKey];
            if (value is num) {
              newValues[config.idField] = value is double ? value : _dN(value);
            } else {
              newValues[config.idField] = _sN(value);
            }
          }
        }
      }

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
      consumeJson: _sN(json['ConsumeJson']),
      unconsumeJson: _sN(json['UnconsumeJson']),
      outputChanges: _sN(json['OutputChanges']),
    );
  }

  // =============================
  // Value getters
  // =============================
  T? getOldValue<T>(String key) => oldValues[key] as T?;
  T? getNewValue<T>(String key) => newValues[key] as T?;

  T? getCurrentValue<T>(String key) =>
      (newValues[key] ?? oldValues[key]) as T?;

  bool hasFieldChanged(String key) => oldValues[key] != newValues[key];

  Set<String> get changedFields {
    final allKeys = <String>{...oldValues.keys, ...newValues.keys};
    return allKeys.where((k) => hasFieldChanged(k)).toSet();
  }

  int get changedFieldsCount => changedFields.length;
}
