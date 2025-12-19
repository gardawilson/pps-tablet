// lib/features/gilingan/view_model/gilingan_production_input_view_model.dart
// Gilingan Production Input ViewModel - adapted from Broker Production pattern
// Supports: Broker (full + partial), Bonggolan (full only), Crusher (full only), Reject (full + partial)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:pps_tablet/features/production/gilingan/repository/gilingan_production_input_repository.dart';

import '../model/gilingan_production_model.dart';
import '../model/gilingan_inputs_model.dart';

// ⬇️ shared lookup result model
import 'package:pps_tablet/features/production/shared/models/production_label_lookup_result.dart';

// -----------------------------------------------------------------------------
// Small value objects
// -----------------------------------------------------------------------------
class TempCommitResult {
  final int added;
  final int skipped;
  const TempCommitResult(this.added, this.skipped);
}

class TempItemsByLabel {
  final String labelCode;
  final List<BrokerItem> brokerItems;
  final List<BrokerItem> brokerPartials;
  final List<BonggolanItem> bonggolanItems;
  final List<CrusherItem> crusherItems;
  final List<RejectItem> rejectItems;
  final List<RejectItem> rejectPartials;
  final DateTime addedAt;

  TempItemsByLabel({
    required this.labelCode,
    this.brokerItems = const [],
    this.brokerPartials = const [],
    this.bonggolanItems = const [],
    this.crusherItems = const [],
    this.rejectItems = const [],
    this.rejectPartials = const [],
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  int get totalCount =>
      brokerItems.length +
          brokerPartials.length +
          bonggolanItems.length +
          crusherItems.length +
          rejectItems.length +
          rejectPartials.length;

  bool get isEmpty => totalCount == 0;

  List<dynamic> get allItems => [
    ...brokerItems,
    ...brokerPartials,
    ...bonggolanItems,
    ...crusherItems,
    ...rejectItems,
    ...rejectPartials,
  ];
}

// -----------------------------------------------------------------------------
// ViewModel
// -----------------------------------------------------------------------------
class GilinganProductionInputViewModel extends ChangeNotifier {
  final GilinganProductionInputRepository repository;
  GilinganProductionInputViewModel({required this.repository});

  // ---------------------------------------------------------------------------
  // Debug control
  // ---------------------------------------------------------------------------
  static const bool _verbose = true;
  void _d(String message) {
    if (kDebugMode && _verbose) debugPrint('[GilinganVM] $message');
  }

  // ---------- DEBUG HELPERS ----------
  String _nn(Object? v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '-' : v.toString();
  String _kg(num? v) => v == null ? '-' : (v is int ? '$v' : v.toStringAsFixed(2));

  String _labelOf(dynamic it) => _getItemLabelCode(it) ?? '-';

  String displayTitleOf(dynamic it) {
    if (it is BrokerItem) {
      return (it.noBrokerPartial ?? '').trim().isNotEmpty
          ? it.noBrokerPartial!
          : _nn(it.noBroker);
    }
    if (it is BonggolanItem) return _nn(it.noBonggolan);
    if (it is CrusherItem) return _nn(it.noCrusher);
    if (it is RejectItem) {
      return (it.noRejectPartial ?? '').trim().isNotEmpty
          ? it.noRejectPartial!
          : _nn(it.noReject);
    }
    return '-';
  }

  String _fmtItem(dynamic it) {
    final t = displayTitleOf(it);
    if (it is BrokerItem) {
      final isPart = (it.noBrokerPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[BROKER•PART] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg'
          : '[BROKER] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg';
    }
    if (it is BonggolanItem) {
      return '[BONGGOL] $t • ${_kg(it.berat)}kg';
    }
    if (it is CrusherItem) {
      return '[CRUSH] $t • ${_kg(it.berat)}kg';
    }
    if (it is RejectItem) {
      final isPart = (it.noRejectPartial ?? '').trim().isNotEmpty;
      return isPart ? '[REJ•PART] $t • ${_kg(it.berat)}kg' : '[REJ] $t • ${_kg(it.berat)}kg';
    }
    return '[UNKNOWN] $it';
  }

  void _dumpList<T>(String name, List<T> list, String Function(T) keyer) {
    _d('$name (${list.length})');
    for (var i = 0; i < list.length; i++) {
      final it = list[i] as dynamic;
      _d('  [$i] ${_fmtItem(it)} | label=${_labelOf(it)} | key=${keyer(it)}');
    }
  }

  void debugDumpTempLists({String tag = ''}) {
    if (!_verbose) return;
    final hdr = tag.isEmpty ? '' : ' <$tag>';
    _d('========== TEMP LIST DUMP$hdr ==========');
    _dumpList('tempBroker', tempBroker, _keyFromBrokerItem);
    _dumpList('tempBrokerPartial', tempBrokerPartial, _keyFromBrokerItem);
    _dumpList('tempBonggolan', tempBonggolan, _keyFromBonggolanItem);
    _dumpList('tempCrusher', tempCrusher, _keyFromCrusherItem);
    _dumpList('tempReject', tempReject, _keyFromRejectItem);
    _dumpList('tempRejectPartial', tempRejectPartial, _keyFromRejectItem);
    _d('TOTAL TEMP COUNT = $totalTempCount');
    _d('========================================');
  }

  void debugDumpTempByLabel() {
    if (!_verbose) return;
    _d('---------- TEMP GROUPED BY LABEL ----------');
    if (_tempItemsByLabel.isEmpty) {
      _d('(empty)');
      return;
    }
    _tempItemsByLabel.forEach((label, bucket) {
      _d('Label "$label" • total=${bucket.totalCount} • since=${bucket.addedAt.toIso8601String()}');
      for (final it in bucket.allItems) {
        _d('  - ${_fmtItem(it)}');
      }
    });
    _d('-------------------------------------------');
  }

  void debugDumpTempKeys({String tag = ''}) {
    if (!_verbose) return;
    final hdr = tag.isEmpty ? '' : ' <$tag>';
    _d('~~~~ TEMP KEYS DUMP$hdr ~~~~');
    _d('_tempKeys (${_tempKeys.length})');
    if (_tempKeys.isEmpty) {
      _d('(empty)');
    } else {
      var i = 0;
      for (final k in _tempKeys) {
        _d('  [$i] $k');
        i++;
        if (i >= 300) {
          _d('  ... (truncated)');
          break;
        }
      }
    }
    _d('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
  }

  // ---------------------------------------------------------------------------
  // Mode: by date (fixed)
  // ---------------------------------------------------------------------------
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<GilinganProduction> items = [];
  bool isLoading = false;
  String error = '';

  // Create state
  bool isSaving = false;
  String? saveError;

  // Prevent duplicate per-row inputs fetch
  final Map<String, Future<GilinganInputs>> _inflight = {};

  // ---------------------------------------------------------------------------
  // Paged mode
  // ---------------------------------------------------------------------------
  late final PagingController<int, GilinganProduction> pagingController;
  int pageSize = 20;

  String _search = '';
  String? _noProduksi;
  bool _exactNoProduksi = false;

  int? _shift;
  DateTime? _date;

  String get search => _search;
  String? get noProduksi => _noProduksi;
  bool get exactNoProduksi => _exactNoProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ---------------------------------------------------------------------------
  // Inputs per row (cache, loading & error per NoProduksi)
  // ---------------------------------------------------------------------------
  final Map<String, GilinganInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noProduksi) => _inputsLoading[noProduksi] == true;
  String? inputsError(String noProduksi) => _inputsError[noProduksi];
  GilinganInputs? inputsOf(String noProduksi) => _inputsCache[noProduksi];
  int inputsCount(String noProduksi, String key) => _inputsCache[noProduksi]?.summary[key] ?? 0;

  Future<GilinganInputs?> loadInputs(String noProduksi, {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) return _inputsCache[noProduksi];
    if (!force && _inflight.containsKey(noProduksi)) {
      try {
        return await _inflight[noProduksi];
      } catch (_) {}
    }

    _inputsLoading[noProduksi] = true;
    _inputsError[noProduksi] = null;
    notifyListeners();

    final future = repository.fetchInputs(noProduksi, force: force);
    _inflight[noProduksi] = future;

    try {
      final result = await future;
      _inputsCache[noProduksi] = result;
      return result;
    } catch (e) {
      _inputsError[noProduksi] = e.toString();
      return null;
    } finally {
      _inflight.remove(noProduksi);
      _inputsLoading[noProduksi] = false;
      notifyListeners();
    }
  }

  void clearInputsCache([String? noProduksi]) {
    if (noProduksi == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      _inputsCache.remove(noProduksi);
      _inputsLoading.remove(noProduksi);
      _inputsError.remove(noProduksi);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lookup label
  // ---------------------------------------------------------------------------
  final Map<String, ProductionLabelLookupResult> _lookupCache = {};
  bool isLookupLoading = false;
  String? lookupError;
  ProductionLabelLookupResult? lastLookup;

  // Track temp items by label code
  final Map<String, TempItemsByLabel> _tempItemsByLabel = {};

  Future<ProductionLabelLookupResult?> lookupLabel(String code, {bool force = false}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      lookupError = 'Kode label kosong';
      notifyListeners();
      return null;
    }

    if (!force && _lookupCache.containsKey(trimmed)) {
      lastLookup = _lookupCache[trimmed];
      lookupError = null;
      notifyListeners();
      return lastLookup;
    }

    isLookupLoading = true;
    lookupError = null;
    notifyListeners();

    try {
      final result = await repository.lookupLabel(trimmed);
      _lookupCache[trimmed] = result;
      lastLookup = result;
      return result;
    } catch (e) {
      lookupError = e.toString();
      return null;
    } finally {
      isLookupLoading = false;
      notifyListeners();
    }
  }

  void clearLookupCache([String? code]) {
    if (code == null) {
      _lookupCache.clear();
    } else {
      _lookupCache.remove(code.trim());
    }
    lastLookup = null;
    lookupError = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Temporary data by label (for rescan UX)
  // ---------------------------------------------------------------------------
  bool hasTemporaryDataForLabel(String labelCode) {
    final tempItems = _tempItemsByLabel[labelCode.trim()];
    return tempItems != null && !tempItems.isEmpty;
  }

  TempItemsByLabel? getTemporaryDataForLabel(String labelCode) =>
      _tempItemsByLabel[labelCode.trim()];

  String getTemporaryDataSummary(String labelCode) {
    final t = getTemporaryDataForLabel(labelCode);
    if (t == null || t.isEmpty) return 'Tidak ada data temporary';
    final s = <String>[];
    if (t.brokerItems.isNotEmpty) s.add('${t.brokerItems.length} Broker');
    if (t.brokerPartials.isNotEmpty) s.add('${t.brokerPartials.length} Broker Partial');
    if (t.bonggolanItems.isNotEmpty) s.add('${t.bonggolanItems.length} Bonggolan');
    if (t.crusherItems.isNotEmpty) s.add('${t.crusherItems.length} Crusher');
    if (t.rejectItems.isNotEmpty) s.add('${t.rejectItems.length} Reject (full)');
    if (t.rejectPartials.isNotEmpty) s.add('${t.rejectPartials.length} Reject Partial');
    return s.join(', ');
  }

  void Function(TempItemsByLabel)? onShowTemporaryDataDialog;
  void showTemporaryDataDialog(String labelCode) {
    final t = getTemporaryDataForLabel(labelCode);
    if (t != null && !t.isEmpty) onShowTemporaryDataDialog?.call(t);
  }

  void removeTemporaryItemsForLabel(String labelCode, List<dynamic> itemsToRemove) {
    final trimmed = labelCode.trim();
    final t = _tempItemsByLabel[trimmed];
    if (t == null) return;

    for (final item in itemsToRemove) {
      if (item is BrokerItem) {
        tempBroker.remove(item);
        tempBrokerPartial.remove(item);
        _tempKeys.remove(_keyFromBrokerItem(item));
      } else if (item is BonggolanItem) {
        tempBonggolan.remove(item);
        _tempKeys.remove(_keyFromBonggolanItem(item));
      } else if (item is CrusherItem) {
        tempCrusher.remove(item);
        _tempKeys.remove(_keyFromCrusherItem(item));
      } else if (item is RejectItem) {
        tempReject.remove(item);
        tempRejectPartial.remove(item);
        _tempKeys.remove(_keyFromRejectItem(item));
      }
    }

    _updateTempItemsByLabel(trimmed);
    notifyListeners();
  }

  void _updateTempItemsByLabel(String labelCode) {
    final code = labelCode.trim();

    final brokerFull = tempBroker.where((e) => _getItemLabelCode(e) == code).toList();
    final brokerPart = tempBrokerPartial.where((e) => _getItemLabelCode(e) == code).toList();
    final bonggolanItems = tempBonggolan.where((e) => _getItemLabelCode(e) == code).toList();
    final crusherItems = tempCrusher.where((e) => _getItemLabelCode(e) == code).toList();
    final rejFull = tempReject.where((e) => _getItemLabelCode(e) == code).toList();
    final rejPart = tempRejectPartial.where((e) => _getItemLabelCode(e) == code).toList();

    if ([brokerFull, brokerPart, bonggolanItems, crusherItems, rejFull, rejPart]
        .every((l) => l.isEmpty)) {
      _tempItemsByLabel.remove(code);
      return;
    }

    _tempItemsByLabel[code] = TempItemsByLabel(
      labelCode: code,
      brokerItems: brokerFull,
      brokerPartials: brokerPart,
      bonggolanItems: bonggolanItems,
      crusherItems: crusherItems,
      rejectItems: rejFull,
      rejectPartials: rejPart,
      addedAt: _tempItemsByLabel[code]?.addedAt ?? DateTime.now(),
    );
  }

  String? _getItemLabelCode(dynamic item) {
    if (item is BrokerItem) {
      final part = (item.noBrokerPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return item.noBroker;
    }

    if (item is BonggolanItem) return item.noBonggolan;

    if (item is CrusherItem) return item.noCrusher;

    if (item is RejectItem) {
      final part = (item.noRejectPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return item.noReject;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Temp selections (anti-duplicate)
  // ---------------------------------------------------------------------------
  final List<BrokerItem> tempBroker = [];
  final List<BrokerItem> tempBrokerPartial = [];
  final List<BonggolanItem> tempBonggolan = [];
  final List<CrusherItem> tempCrusher = [];
  final List<RejectItem> tempReject = [];
  final List<RejectItem> tempRejectPartial = [];

  final Set<String> _pickedKeys = <String>{};
  final List<Map<String, dynamic>> _pickedRows = <Map<String, dynamic>>[];
  final Map<String, int> _keyToRowIndex = {};

  // Keys we manage
  final Set<String> _tempKeys = <String>{};

  // ====== key builders ======
  String _keyFromBrokerItem(BrokerItem i) =>
      'D.|Broker_d|${i.noBroker ?? '-'}|${(i.noSak ?? '').toString().trim()}';
  String _keyFromBonggolanItem(BonggolanItem i) =>
      'E.|Bonggolan|${i.noBonggolan ?? '-'}|';
  String _keyFromCrusherItem(CrusherItem i) =>
      'F.|Crusher|${i.noCrusher ?? '-'}|';
  String _keyFromRejectItem(RejectItem i) =>
      'BF.|RejectV2|${i.noReject ?? '-'}|';

  // ====== keys in DB (from cache) ======
  Set<String> _dbKeysFor(String noProduksi) {
    final keys = <String>{};
    final db = _inputsCache[noProduksi];
    if (db != null) {
      for (final x in db.broker) keys.add(_keyFromBrokerItem(x));
      for (final x in db.bonggolan) keys.add(_keyFromBonggolanItem(x));
      for (final x in db.crusher) keys.add(_keyFromCrusherItem(x));
      for (final x in db.reject) keys.add(_keyFromRejectItem(x));
    }
    return keys;
  }

  // ====== DB + TEMP ======
  Set<String> _allKeysFor(String noProduksi) {
    final all = _dbKeysFor(noProduksi);
    all.addAll(_tempKeys);
    return all;
  }

  // ====== PUBLIC API (TEMP-only duplicate checks) ======
  bool isRowAlreadyPresent(Map<String, dynamic> row, String noProduksi) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    final simpleKey = ctx.simpleKey(row);
    return _tempKeys.contains(simpleKey);
  }

  int countNewRowsInLastLookup(String noProduksi) {
    final ctx = lastLookup;
    if (ctx == null) return 0;
    return ctx.data.where((r) => !_tempKeys.contains(ctx.simpleKey(r))).length;
  }

  bool willBeDuplicate(Map<String, dynamic> row, String noProduksi) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    final simpleKey = ctx.simpleKey(row);
    return _tempKeys.contains(simpleKey);
  }

  // Picks (UI)
  void togglePick(Map<String, dynamic> row) {
    final ctx = lastLookup;
    if (ctx == null) return;
    final index = ctx.data.indexOf(row);
    if (index == -1) return;

    final uniqueKey = ctx.rowKey(row);
    if (_pickedKeys.contains(uniqueKey)) {
      _pickedKeys.remove(uniqueKey);
      _pickedRows.removeWhere((r) => ctx.data.indexOf(r) == index);
      _keyToRowIndex.remove(uniqueKey);
    } else {
      _pickedKeys.add(uniqueKey);
      _pickedRows.add(row);
      _keyToRowIndex[uniqueKey] = index;
    }
    notifyListeners();
  }

  bool isPicked(Map<String, dynamic> row) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    return _pickedKeys.contains(ctx.rowKey(row));
  }

  int get pickedCount => _pickedKeys.length;
  bool get hasPicked => _pickedKeys.isNotEmpty;

  String get pickedSummary {
    final ctx = lastLookup;
    if (ctx == null || !hasPicked) return '';
    return '${pickedCount} ${ctx.prefixType.displayName} dipilih';
  }

  void pickAllNew(String noProduksi) {
    final ctx = lastLookup;
    if (ctx == null) return;

    for (int i = 0; i < ctx.data.length; i++) {
      final row = ctx.data[i];
      final key = ctx.simpleKey(row);
      if (!_tempKeys.contains(key) && ctx.isRowValid(row)) {
        final uniqueKey = ctx.rowKey(row);
        if (_pickedKeys.add(uniqueKey)) {
          _pickedRows.add(row);
          _keyToRowIndex[uniqueKey] = i;
        }
      }
    }
    notifyListeners();
  }

  void unpickAll() => clearPicks();
  List<Map<String, dynamic>> get pickedRows => List.unmodifiable(_pickedRows);

  void clearPicks() {
    _pickedKeys.clear();
    _pickedRows.clear();
    _keyToRowIndex.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Commit picked → TEMP (strict anti-duplicate)
  // ---------------------------------------------------------------------------
  bool _rowIsPartial(Map<String, dynamic> row, PrefixType t) {
    final candKeys = const ['IsPartial', 'isPartial', 'IsPartialRow', 'isPartialRow'];
    for (final k in candKeys) {
      final v = row[k];
      if (v is bool && v) return true;
      if (v is num && v != 0) return true;
      if (v is String && (v == '1' || v.toLowerCase() == 'true')) return true;
    }
    switch (t) {
      case PrefixType.broker:
        final s = (row['NoBrokerPartial'] ?? row['noBrokerPartial'] ?? '').toString().trim();
        return s.isNotEmpty;
      case PrefixType.reject:
        final s = (row['NoRejectPartial'] ?? row['noRejectPartial'] ?? '').toString().trim();
        return s.isNotEmpty;
      default:
        return false;
    }
  }

  TempCommitResult commitPickedToTemp({required String noProduksi}) {
    final ctx = lastLookup;
    if (ctx == null || _pickedRows.isEmpty) return const TempCommitResult(0, 0);

    final Set<String> seenTemp = Set<String>.from(_tempKeys);

    int added = 0, skipped = 0;

    final filteredData = List<Map<String, dynamic>>.from(_pickedRows);
    final filteredCtx = ProductionLabelLookupResult(
      found: ctx.found,
      message: ctx.message,
      prefix: ctx.prefix,
      tableName: ctx.tableName,
      totalRecords: filteredData.length,
      data: filteredData,
      raw: ctx.raw,
    );

    final typedItems = filteredCtx.typedItems;
    final Set<String> affectedLabels = <String>{};

    for (int i = 0; i < typedItems.length; i++) {
      final item = typedItems[i];
      final rawRow = filteredData[i];

      final simpleKey = ctx.simpleKey(rawRow);
      final bool isPartial = _rowIsPartial(rawRow, ctx.prefixType);

      bool shouldSkip = false;

      if (isPartial) {
        final baseKey = _getBaseKeyWithoutWeight(rawRow, ctx.prefixType);
        final existingPartial = _findExistingPartialItem(item, ctx.prefixType);

        if (existingPartial != null) {
          final existingWeight = _getWeightFromItem(existingPartial);
          final newWeight = rawRow['berat'] ?? rawRow['Berat'];

          if (existingWeight == newWeight) {
            shouldSkip = true;
          }
        }
      } else {
        if (seenTemp.contains(simpleKey)) {
          shouldSkip = true;
        }
      }

      if (shouldSkip) {
        skipped++;
        continue;
      }

      final String tempKey =
      item is BrokerItem ? _keyFromBrokerItem(item)
          : item is BonggolanItem ? _keyFromBonggolanItem(item)
          : item is CrusherItem ? _keyFromCrusherItem(item)
          : item is RejectItem ? _keyFromRejectItem(item)
          : simpleKey;

      if (!_tempKeys.add(tempKey)) {
        skipped++;
        continue;
      }
      seenTemp.add(simpleKey);

      final newItem = _withTempPartialIfNeeded(item, ctx.prefixType, isPartial);

      bool itemAdded = false;
      if (newItem is BrokerItem) {
        if (newItem.isPartialRow) {
          tempBrokerPartial.add(newItem);
        } else {
          tempBroker.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is BonggolanItem) {
        tempBonggolan.add(newItem);
        itemAdded = true;
      } else if (newItem is CrusherItem) {
        tempCrusher.add(newItem);
        itemAdded = true;
      } else if (newItem is RejectItem) {
        if (newItem.isPartialRow) {
          tempRejectPartial.add(newItem);
        } else {
          tempReject.add(newItem);
        }
        itemAdded = true;
      }

      if (itemAdded) {
        final code = _getItemLabelCode(newItem);
        if (code != null && code.trim().isNotEmpty) affectedLabels.add(code.trim());
        added++;
      } else {
        _tempKeys.remove(tempKey);
        skipped++;
      }
    }

    for (final label in affectedLabels) {
      _updateTempItemsByLabel(label);
    }

    debugDumpTempLists(tag: 'after commitPickedToTemp');
    debugDumpTempByLabel();
    debugDumpTempKeys(tag: 'after commit');

    clearPicks();
    notifyListeners();
    return TempCommitResult(added, skipped);
  }

  // Helper methods for partial checks
  String _getBaseKeyWithoutWeight(Map<String, dynamic> row, PrefixType type) {
    switch (type) {
      case PrefixType.broker:
        final noBroker = row['NoBroker'] ?? row['noBroker'] ?? '';
        final noSak = row['NoSak'] ?? row['noSak'] ?? '';
        return 'D.|Broker_d|$noBroker|$noSak';
      case PrefixType.bonggolan:
        final noBonggol = row['NoBonggolan'] ?? row['noBonggolan'] ?? '';
        return 'E.|Bonggolan|$noBonggol';
      case PrefixType.crusher:
        final noCrusher = row['NoCrusher'] ?? row['noCrusher'] ?? '';
        return 'F.|Crusher|$noCrusher';
      case PrefixType.reject:
        final noRej = row['NoReject'] ?? row['noReject'] ?? '';
        return 'BF.|RejectV2|$noRej';
      default:
        return '';
    }
  }

  dynamic _findExistingPartialItem(dynamic item, PrefixType type) {
    if (item is BrokerItem) {
      for (final existing in tempBrokerPartial) {
        if (existing.noBroker == item.noBroker &&
            existing.noSak == item.noSak) {
          return existing;
        }
      }
    } else if (item is RejectItem) {
      for (final existing in tempRejectPartial) {
        if (existing.noReject == item.noReject) {
          return existing;
        }
      }
    }
    return null;
  }

  double? _getWeightFromItem(dynamic item) {
    if (item is BrokerItem) return item.berat;
    if (item is BonggolanItem) return item.berat;
    if (item is CrusherItem) return item.berat;
    if (item is RejectItem) return item.berat;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Delete temp items
  // ---------------------------------------------------------------------------
  void deleteTempBrokerItem(BrokerItem item) {
    tempBroker.remove(item);
    tempBrokerPartial.remove(item);
    _tempKeys.remove(_keyFromBrokerItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempBrokerItem');
    notifyListeners();
  }

  void deleteTempBonggolanItem(BonggolanItem item) {
    tempBonggolan.remove(item);
    _tempKeys.remove(_keyFromBonggolanItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempBonggolanItem');
    notifyListeners();
  }

  void deleteTempCrusherItem(CrusherItem item) {
    tempCrusher.remove(item);
    _tempKeys.remove(_keyFromCrusherItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempCrusherItem');
    notifyListeners();
  }

  void deleteTempRejectItem(RejectItem item) {
    tempReject.remove(item);
    tempRejectPartial.remove(item);
    _tempKeys.remove(_keyFromRejectItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempRejectItem');
    notifyListeners();
  }

  bool isInTempKeys(String key) => _tempKeys.contains(key);
  Set<String> getTempKeysForDebug() => Set.unmodifiable(_tempKeys);

  void clearAllTempItems() {
    tempBroker.clear();
    tempBrokerPartial.clear();
    tempBonggolan.clear();
    tempCrusher.clear();
    tempReject.clear();
    tempRejectPartial.clear();

    _tempKeys.clear();
    _tempItemsByLabel.clear();
    clearPicks();
    _tempPartialSeq.updateAll((_, __) => 0);

    _d('clearAllTempItems() called');
    debugDumpTempLists(tag: 'after clearAllTempItems');
    debugDumpTempByLabel();
    debugDumpTempKeys(tag: 'after clearAllTempItems');

    notifyListeners();
  }

  bool deleteIfTemp(dynamic item) {
    bool ok = false;
    if (item is BrokerItem) {
      ok = tempBroker.remove(item) || tempBrokerPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromBrokerItem(item));
    } else if (item is BonggolanItem) {
      ok = tempBonggolan.remove(item);
      if (ok) _tempKeys.remove(_keyFromBonggolanItem(item));
    } else if (item is CrusherItem) {
      ok = tempCrusher.remove(item);
      if (ok) _tempKeys.remove(_keyFromCrusherItem(item));
    } else if (item is RejectItem) {
      ok = tempReject.remove(item) || tempRejectPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromRejectItem(item));
    }
    if (ok) debugDumpTempLists(tag: 'after deleteIfTemp');
    return ok;
  }

  int deleteAllTempForLabel(String labelCode) {
    final t = _tempItemsByLabel[labelCode.trim()];
    if (t == null || t.isEmpty) return 0;

    int removed = 0;
    for (final it in t.allItems) {
      if (deleteIfTemp(it)) removed++;
    }
    _updateTempItemsByLabel(labelCode);

    debugDumpTempLists(tag: 'after deleteAllTempForLabel:$labelCode');
    debugDumpTempByLabel();
    debugDumpTempKeys(tag: 'after deleteAllTempForLabel');

    if (removed > 0) notifyListeners();
    return removed;
  }

  // ===== Temp-partial numbering state =====
  final Map<PrefixType, int> _tempPartialSeq = {
    PrefixType.broker: 0,
    PrefixType.reject: 0,
  };

  int _nextPartialSeq(PrefixType t) {
    final n = (_tempPartialSeq[t] ?? 0) + 1;
    _tempPartialSeq[t] = n;
    return n;
  }

  String _formatTempPartial(PrefixType tp, int seq) {
    final numStr = seq.toString().padLeft(1, '0');
    switch (tp) {
      case PrefixType.broker:
        return 'Q.XXXXXXXX ($numStr)';
      case PrefixType.reject:
        return 'BK.XXXXXXXX ($numStr)';
      default:
        return '';
    }
  }

  dynamic _withTempPartialIfNeeded(dynamic item, PrefixType t, bool isPartial) {
    final supports = t == PrefixType.broker || t == PrefixType.reject;
    if (!supports || !isPartial) return item;

    if (item is BrokerItem) {
      final already = (item.noBrokerPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noBrokerPartial: code);
      }
      return item;
    }

    if (item is RejectItem) {
      final already = (item.noRejectPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noRejectPartial: code);
      }
      return item;
    }

    return item;
  }

  int get totalTempCount =>
      tempBroker.length +
          tempBrokerPartial.length +
          tempBonggolan.length +
          tempCrusher.length +
          tempReject.length +
          tempRejectPartial.length;

  // ---------------------------------------------------------------------------
  // Submit temp items to backend
  // ---------------------------------------------------------------------------
  bool isSubmitting = false;
  String? submitError;

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{};

    if (tempBroker.isNotEmpty) {
      payload['broker'] = tempBroker.map((e) => {
        'noBroker': e.noBroker,
        'noSak': e.noSak,
      }).toList();
    }

    if (tempBonggolan.isNotEmpty) {
      payload['bonggolan'] = tempBonggolan.map((e) => {
        'noBonggolan': e.noBonggolan,
      }).toList();
    }

    if (tempCrusher.isNotEmpty) {
      payload['crusher'] = tempCrusher.map((e) => {
        'noCrusher': e.noCrusher,
      }).toList();
    }

    if (tempReject.isNotEmpty) {
      payload['reject'] = tempReject.map((e) => {
        'noReject': e.noReject,
      }).toList();
    }

    if (tempBrokerPartial.isNotEmpty) {
      payload['brokerPartialNew'] = tempBrokerPartial.map((e) => {
        'noBroker': e.noBroker,
        'noSak': e.noSak,
        'berat': e.berat,
      }).toList();
    }

    if (tempRejectPartial.isNotEmpty) {
      payload['rejectPartialNew'] = tempRejectPartial.map((e) => {
        'noReject': e.noReject,
        'berat': e.berat,
      }).toList();
    }

    return payload;
  }

  Future<bool> submitTempItems(String noProduksi) async {
    if (totalTempCount == 0) {
      submitError = 'Tidak ada data untuk disubmit';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      final payload = _buildPayload();

      _d('Submitting temp items to $noProduksi');
      _d('Payload: ${json.encode(payload)}');

      final response = await repository.submitInputsAndPartials(
        noProduksi,
        payload,
      );

      _d('Submit response: ${json.encode(response)}');

      final success = response['success'] as bool? ?? false;
      final data = response['data'] as Map<String, dynamic>?;

      if (!success) {
        final message = response['message'] as String? ?? 'Submit gagal';
        submitError = message;

        if (data != null) {
          final details = data['details'] as Map<String, dynamic>?;
          if (details != null) {
            _d('Submit details: ${json.encode(details)}');
          }
        }

        return false;
      }

      _d('Submit successful!');

      if (data != null) {
        final createdPartials = data['createdPartials'] as Map<String, dynamic>?;
        if (createdPartials != null) {
          _d('Created partials: ${json.encode(createdPartials)}');
        }
      }

      clearAllTempItems();
      clearLookupCache();
      clearInputsCache(noProduksi);
      await loadInputs(noProduksi, force: true);

      return true;
    } catch (e) {
      _d('Submit error: $e');
      submitError = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String getSubmitSummary() {
    if (totalTempCount == 0) return 'Tidak ada data';

    final parts = <String>[];

    if (tempBroker.isNotEmpty) {
      parts.add('${tempBroker.length} Broker');
    }
    if (tempBrokerPartial.isNotEmpty) {
      parts.add('${tempBrokerPartial.length} Broker Partial');
    }
    if (tempBonggolan.isNotEmpty) {
      parts.add('${tempBonggolan.length} Bonggolan');
    }
    if (tempCrusher.isNotEmpty) {
      parts.add('${tempCrusher.length} Crusher');
    }
    if (tempReject.isNotEmpty) {
      parts.add('${tempReject.length} Reject');
    }
    if (tempRejectPartial.isNotEmpty) {
      parts.add('${tempRejectPartial.length} Reject Partial');
    }

    return 'Total $totalTempCount items:\n${parts.join(', ')}';
  }

  // ---------------------------------------------------------------------------
  // Delete inputs & partials (DB + TEMP)
  // ---------------------------------------------------------------------------
  bool isDeleting = false;
  String? deleteError;
  Map<String, dynamic>? lastDeleteResult;

  Map<String, dynamic> _buildDeletePayloadFromItems(List<dynamic> items) {
    final payload = <String, dynamic>{};

    void add(String key, Map<String, dynamic> row) {
      final list = (payload[key] ?? <Map<String, dynamic>>[]) as List<Map<String, dynamic>>;
      list.add(row);
      payload[key] = list;
    }

    for (final it in items) {
      if (it is BrokerItem) {
        final isPart = it.isPartialRow ||
            ((it.noBrokerPartial ?? '').trim().isNotEmpty);
        if (isPart) {
          final code = (it.noBrokerPartial ?? '').trim();
          if (code.isNotEmpty) {
            add('brokerPartial', {
              'noBrokerPartial': code,
            });
          }
        } else {
          add('broker', {
            'noBroker': it.noBroker,
            'noSak': it.noSak,
          });
        }
      } else if (it is BonggolanItem) {
        add('bonggolan', {
          'noBonggolan': it.noBonggolan,
        });
      } else if (it is CrusherItem) {
        add('crusher', {
          'noCrusher': it.noCrusher,
        });
      } else if (it is RejectItem) {
        final isPart = it.isPartialRow ||
            ((it.noRejectPartial ?? '').trim().isNotEmpty);
        if (isPart) {
          final code = (it.noRejectPartial ?? '').trim();
          if (code.isNotEmpty) {
            add('rejectPartial', {
              'noRejectPartial': code,
            });
          }
        } else {
          add('reject', {
            'noReject': it.noReject,
          });
        }
      }
    }

    return payload;
  }

  Future<bool> deleteItems(String noProduksi, List<dynamic> items) async {
    if (items.isEmpty) {
      deleteError = 'Tidak ada data yang dipilih untuk dihapus';
      notifyListeners();
      return false;
    }

    final List<dynamic> dbItems = [];

    for (final it in items) {
      final removedFromTemp = deleteIfTemp(it);
      if (!removedFromTemp) {
        dbItems.add(it);
      }
    }

    if (dbItems.isEmpty) {
      _d('deleteItems: hanya menghapus TEMP, tidak call API');
      notifyListeners();
      return true;
    }

    final payload = _buildDeletePayloadFromItems(dbItems);
    if (payload.isEmpty) {
      deleteError = 'Tidak ada data valid untuk dihapus (payload kosong)';
      notifyListeners();
      return false;
    }

    isDeleting = true;
    deleteError = null;
    notifyListeners();

    try {
      _d('deleteItems: calling deleteInputsAndPartials for $noProduksi');
      _d('Delete payload: ${json.encode(payload)}');

      final res = await repository.deleteInputsAndPartials(noProduksi, payload);
      lastDeleteResult = res;

      final success = res['success'] == true;
      final message = res['message'] as String? ?? '';

      _d('Delete response: ${json.encode(res)}');

      if (!success) {
        deleteError = message.isEmpty ? 'Gagal menghapus data' : message;
        return false;
      }

      clearInputsCache(noProduksi);
      await loadInputs(noProduksi, force: true);

      return true;
    } catch (e) {
      _d('Delete error: $e');
      deleteError = e.toString();
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    try {
      pagingController.dispose();
    } catch (_) {}
    super.dispose();
  }
}