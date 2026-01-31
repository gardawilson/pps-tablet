import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../model/sortir_reject_inputs_model.dart';

// shared lookup result model (dipakai untuk lookup label)
import 'package:pps_tablet/features/production/shared/models/production_label_lookup_result.dart';

// item models (shared)
import 'package:pps_tablet/features/production/shared/models/furniture_wip_item.dart';
import 'package:pps_tablet/features/production/shared/models/cabinet_material_item.dart';
import 'package:pps_tablet/features/production/shared/models/barang_jadi_item.dart';

import '../repository/sortir_reject_production_input_repository.dart';

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

  final List<BarangJadiItem> barangJadiItems;
  final List<BarangJadiItem> barangJadiPartials;

  final List<FurnitureWipItem> furnitureWipItems;
  final List<FurnitureWipItem> furnitureWipPartials;

  final DateTime addedAt;

  TempItemsByLabel({
    required this.labelCode,
    this.barangJadiItems = const [],
    this.barangJadiPartials = const [],
    this.furnitureWipItems = const [],
    this.furnitureWipPartials = const [],
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  int get totalCount =>
      barangJadiItems.length +
          barangJadiPartials.length +
          furnitureWipItems.length +
          furnitureWipPartials.length;

  bool get isEmpty => totalCount == 0;

  List<dynamic> get allItems => [
    ...barangJadiItems,
    ...barangJadiPartials,
    ...furnitureWipItems,
    ...furnitureWipPartials,
  ];
}

// -----------------------------------------------------------------------------
// ViewModel
// -----------------------------------------------------------------------------
class SortirRejectInputViewModel extends ChangeNotifier {
  final SortirRejectInputRepository repository;
  SortirRejectInputViewModel({required this.repository});

  // ---------------------------------------------------------------------------
  // Debug control
  // ---------------------------------------------------------------------------
  static const bool _verbose = true;

  void _d(String message) {
    if (kDebugMode && _verbose) debugPrint('[SortirRejectInputVM] $message');
  }

  String _nn(Object? v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '-' : v.toString();

  String _kg(num? v) =>
      v == null ? '-' : (v is int ? '$v' : v.toStringAsFixed(2));

  // ---------------------------------------------------------------------------
  // Label normalize (PENTING untuk "kuning")
  // ---------------------------------------------------------------------------
  String _normLabel(String s) => s.trim().toUpperCase();

  String _labelOf(dynamic it) => _getItemLabelCode(it) ?? '-';

  // Untuk display title: partial dulu, baru full
  String displayTitleOf(dynamic it) {
    if (it is BarangJadiItem) {
      final part = (it.noBJPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return _nn(it.noBJ);
    }
    if (it is FurnitureWipItem) {
      final part = (it.noFurnitureWIPPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return _nn(it.noFurnitureWIP);
    }
    if (it is CabinetMaterialItem) {
      return it.Nama ?? 'Material ${it.IdCabinetMaterial ?? 0}';
    }
    return '-';
  }

  String _fmtItem(dynamic it) {
    final t = displayTitleOf(it);

    if (it is BarangJadiItem) {
      final isPart = (it.noBJPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[BJ•PART] $t • ${it.pcs ?? 0} pcs • ${_kg(it.berat)}kg'
          : '[BJ] $t • ${it.pcs ?? 0} pcs • ${_kg(it.berat)}kg';
    }

    if (it is FurnitureWipItem) {
      final isPart = (it.noFurnitureWIPPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[FWIP•PART] $t • ${it.pcs ?? 0} pcs • ${_kg(it.berat)}kg'
          : '[FWIP] $t • ${it.pcs ?? 0} pcs • ${_kg(it.berat)}kg';
    }

    if (it is CabinetMaterialItem) {
      final j = it.Jumlah ?? 0;
      final u = it.NamaUOM ?? 'unit';
      final s = it.SaldoAkhir ?? 0;
      return '[MAT] $t • Jumlah=$j $u • SaldoAkhir=$s $u';
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

    _dumpList('tempBarangJadi', tempBarangJadi, _payloadKeyFromBarangJadiItem);
    _dumpList('tempBarangJadiPartial', tempBarangJadiPartial,
        _payloadKeyFromBarangJadiItem);

    _dumpList(
        'tempFurnitureWip', tempFurnitureWip, _payloadKeyFromFurnitureWipItem);
    _dumpList('tempFurnitureWipPartial', tempFurnitureWipPartial,
        _payloadKeyFromFurnitureWipItem);

    _dumpList('tempCabinetMaterial', tempCabinetMaterial,
        _keyFromCabinetMaterialItem);

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
      _d(
          'Label "$label" • total=${bucket.totalCount} • since=${bucket.addedAt.toIso8601String()}');
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
  // Inputs per row (cache, loading & error per NoBJSortir)
  // ---------------------------------------------------------------------------
  final Map<String, SortirRejectInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};
  final Map<String, Future<SortirRejectInputs>> _inflight = {};

  bool isInputsLoading(String noBJSortir) => _inputsLoading[noBJSortir] == true;
  String? inputsError(String noBJSortir) => _inputsError[noBJSortir];
  SortirRejectInputs? inputsOf(String noBJSortir) => _inputsCache[noBJSortir];

  int inputsCount(String noBJSortir, String key) =>
      _inputsCache[noBJSortir]?.summary[key] ?? 0;

  Future<SortirRejectInputs?> loadInputs(String noBJSortir,
      {bool force = false}) async {
    final key = noBJSortir.trim();
    if (key.isEmpty) return null;

    if (!force && _inputsCache.containsKey(key)) return _inputsCache[key];
    if (!force && _inflight.containsKey(key)) {
      try {
        return await _inflight[key];
      } catch (_) {}
    }

    _inputsLoading[key] = true;
    _inputsError[key] = null;
    notifyListeners();

    final future = repository.fetchInputs(key, force: force);
    _inflight[key] = future;

    try {
      final result = await future;
      _inputsCache[key] = result;
      return result;
    } catch (e) {
      _inputsError[key] = e.toString();
      return null;
    } finally {
      _inflight.remove(key);
      _inputsLoading[key] = false;
      notifyListeners();
    }
  }

  void clearInputsCache([String? noBJSortir]) {
    if (noBJSortir == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      final key = noBJSortir.trim();
      _inputsCache.remove(key);
      _inputsLoading.remove(key);
      _inputsError.remove(key);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Master Cabinet Materials
  // ---------------------------------------------------------------------------
  final Map<int, List<CabinetMaterialItem>> _masterCabinetByWh = {};
  final Map<int, bool> _masterCabinetLoading = {};
  final Map<int, String?> _masterCabinetError = {};

  bool isMasterCabinetLoading(int idWarehouse) =>
      _masterCabinetLoading[idWarehouse] == true;

  String? masterCabinetError(int idWarehouse) =>
      _masterCabinetError[idWarehouse];

  List<CabinetMaterialItem> masterCabinetMaterials(int idWarehouse) =>
      _masterCabinetByWh[idWarehouse] ?? const [];

  Future<List<CabinetMaterialItem>> loadMasterCabinetMaterials({
    required int idWarehouse,
    bool force = false,
  }) async {
    if (!force && _masterCabinetByWh.containsKey(idWarehouse)) {
      return _masterCabinetByWh[idWarehouse]!;
    }

    _masterCabinetLoading[idWarehouse] = true;
    _masterCabinetError[idWarehouse] = null;
    notifyListeners();

    try {
      final items = await repository.fetchMasterCabinetMaterials(
        idWarehouse: idWarehouse,
        force: force,
      );
      _masterCabinetByWh[idWarehouse] = items;
      return items;
    } catch (e) {
      _masterCabinetError[idWarehouse] = e.toString();
      return const [];
    } finally {
      _masterCabinetLoading[idWarehouse] = false;
      notifyListeners();
    }
  }

  void clearMasterCabinetCache([int? idWarehouse]) {
    if (idWarehouse == null) {
      _masterCabinetByWh.clear();
      _masterCabinetLoading.clear();
      _masterCabinetError.clear();
    } else {
      _masterCabinetByWh.remove(idWarehouse);
      _masterCabinetLoading.remove(idWarehouse);
      _masterCabinetError.remove(idWarehouse);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lookup label (scan)
  // ---------------------------------------------------------------------------
  final Map<String, ProductionLabelLookupResult> _lookupCache = {};
  bool isLookupLoading = false;
  String? lookupError;
  ProductionLabelLookupResult? lastLookup;

  final Map<String, TempItemsByLabel> _tempItemsByLabel = {};

  Future<ProductionLabelLookupResult?> lookupLabel(
      String code, {
        bool force = false,
      }) async {
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
  // Temporary data by label (dipakai untuk "kuning")
  // ---------------------------------------------------------------------------
  bool hasTemporaryDataForLabel(String labelCode) {
    final t = _tempItemsByLabel[_normLabel(labelCode)];
    return t != null && !t.isEmpty;
  }

  TempItemsByLabel? getTemporaryDataForLabel(String labelCode) =>
      _tempItemsByLabel[_normLabel(labelCode)];

  String getTemporaryDataSummary(String labelCode) {
    final t = getTemporaryDataForLabel(labelCode);
    if (t == null || t.isEmpty) return 'Tidak ada data temporary';

    final s = <String>[];
    if (t.barangJadiItems.isNotEmpty) {
      s.add('${t.barangJadiItems.length} BJ (full)');
    }
    if (t.barangJadiPartials.isNotEmpty) {
      s.add('${t.barangJadiPartials.length} BJ Partial');
    }
    if (t.furnitureWipItems.isNotEmpty) {
      s.add('${t.furnitureWipItems.length} FWIP (full)');
    }
    if (t.furnitureWipPartials.isNotEmpty) {
      s.add('${t.furnitureWipPartials.length} FWIP Partial');
    }
    return s.join(', ');
  }

  void Function(TempItemsByLabel)? onShowTemporaryDataDialog;
  void showTemporaryDataDialog(String labelCode) {
    final t = getTemporaryDataForLabel(labelCode);
    if (t != null && !t.isEmpty) onShowTemporaryDataDialog?.call(t);
  }

  void removeTemporaryItemsForLabel(
      String labelCode, List<dynamic> itemsToRemove) {
    final code = _normLabel(labelCode);
    final t = _tempItemsByLabel[code];
    if (t == null) return;

    for (final item in itemsToRemove) {
      deleteIfTemp(item);
    }

    _updateTempItemsByLabel(code);
    notifyListeners();
  }

  void _updateTempItemsByLabel(String labelCode) {
    final code = _normLabel(labelCode);
    if (code.isEmpty) return;

    bool match(dynamic e) => _normLabel(_getItemLabelCode(e) ?? '') == code;

    final bjFull = tempBarangJadi.where(match).toList();
    final bjPart = tempBarangJadiPartial.where(match).toList();

    final fwFull = tempFurnitureWip.where(match).toList();
    final fwPart = tempFurnitureWipPartial.where(match).toList();

    final allEmpty =
        bjFull.isEmpty && bjPart.isEmpty && fwFull.isEmpty && fwPart.isEmpty;
    if (allEmpty) {
      _tempItemsByLabel.remove(code);
      return;
    }

    _tempItemsByLabel[code] = TempItemsByLabel(
      labelCode: code,
      barangJadiItems: bjFull,
      barangJadiPartials: bjPart,
      furnitureWipItems: fwFull,
      furnitureWipPartials: fwPart,
      addedAt: _tempItemsByLabel[code]?.addedAt ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // TEMP lists
  // ---------------------------------------------------------------------------
  final List<BarangJadiItem> tempBarangJadi = [];
  final List<BarangJadiItem> tempBarangJadiPartial = [];

  final List<FurnitureWipItem> tempFurnitureWip = [];
  final List<FurnitureWipItem> tempFurnitureWipPartial = [];

  final List<CabinetMaterialItem> tempCabinetMaterial = [];

  // picks (UI)
  final Set<String> _pickedKeys = <String>{};
  final List<Map<String, dynamic>> _pickedRows = <Map<String, dynamic>>[];
  final Map<String, int> _keyToRowIndex = {};

  // ✅ IMPORTANT: _tempKeys harus menyimpan ctx.simpleKey(row)
  final Set<String> _tempKeys = <String>{};

  // ✅ FIX: mapping item TEMP -> simpleKey (supaya delete bersih)
  final Map<String, String> _tempItemToSimpleKey = <String, String>{};

  bool isInTempKeys(String key) => _tempKeys.contains(key.trim());
  Set<String> getTempKeysForDebug() => Set.unmodifiable(_tempKeys);

  // ===== payload keys untuk mapping delete =====
  String _payloadKeyFromBarangJadiItem(BarangJadiItem i) {
    final no = (i.noBJ ?? '').trim();
    final part = (i.noBJPartial ?? '').trim();
    // part boleh kosong -> tetap stable
    return 'BJ|$no|$part';
  }

  String _payloadKeyFromFurnitureWipItem(FurnitureWipItem i) {
    final no = (i.noFurnitureWIP ?? '').trim();
    final part = (i.noFurnitureWIPPartial ?? '').trim();
    return 'FWIP|$no|$part';
  }

  String _keyFromCabinetMaterialItem(CabinetMaterialItem i) =>
      'MAT|${i.IdCabinetMaterial ?? 0}';

  // label code grouping helper (bucket per label)
  String? _getItemLabelCode(dynamic item) {
    if (item is BarangJadiItem) {
      final p = (item.noBJPartial ?? '').trim();
      if (p.isNotEmpty) return p;
      final b = (item.noBJ ?? '').trim();
      return b.isNotEmpty ? b : null;
    }
    if (item is FurnitureWipItem) {
      final p = (item.noFurnitureWIPPartial ?? '').trim();
      if (p.isNotEmpty) return p;
      final b = (item.noFurnitureWIP ?? '').trim();
      return b.isNotEmpty ? b : null;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Duplicate helpers (TEMP-ONLY, meniru Broker)
  // ---------------------------------------------------------------------------
  bool isRowAlreadyPresent(Map<String, dynamic> row, String noBJSortir) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    final sk = ctx.simpleKey(row).trim();
    return _tempKeys.contains(sk);
  }

  bool willBeDuplicate(Map<String, dynamic> row, String noBJSortir) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    final sk = ctx.simpleKey(row).trim();
    return _tempKeys.contains(sk);
  }

  int countNewRowsInLastLookup(String noBJSortir) {
    final ctx = lastLookup;
    if (ctx == null) return 0;

    int fresh = 0;
    for (final row in ctx.data) {
      if (!ctx.isRowValid(row)) continue;
      final sk = ctx.simpleKey(row).trim();
      if (_tempKeys.contains(sk)) continue;
      fresh++;
    }
    return fresh;
  }

  // ---------------------------------------------------------------------------
  // Picks (UI)
  // ---------------------------------------------------------------------------
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
    return '$pickedCount ${ctx.prefixType.displayName} dipilih';
  }

  List<Map<String, dynamic>> get pickedRows => List.unmodifiable(_pickedRows);

  void clearPicks() {
    _pickedKeys.clear();
    _pickedRows.clear();
    _keyToRowIndex.clear();
    notifyListeners();
  }

  void pickAllNew(String noBJSortir) {
    final ctx = lastLookup;
    if (ctx == null) return;

    for (int i = 0; i < ctx.data.length; i++) {
      final row = ctx.data[i];
      if (!ctx.isRowValid(row)) continue;

      final sk = ctx.simpleKey(row).trim();
      if (_tempKeys.contains(sk)) continue; // TEMP-only

      final uniqueKey = ctx.rowKey(row);
      if (_pickedKeys.add(uniqueKey)) {
        _pickedRows.add(row);
        _keyToRowIndex[uniqueKey] = i;
      }
    }

    notifyListeners();
  }

  void unpickAll() => clearPicks();

  // ---------------------------------------------------------------------------
  // TEMP PARTIAL DISPLAY FORMAT
  // ---------------------------------------------------------------------------
  int _tempPartialSeqBJ = 0;
  int _tempPartialSeqFW = 0;

  int _nextSeqBJ() => ++_tempPartialSeqBJ;
  int _nextSeqFW() => ++_tempPartialSeqFW;

  String _formatTempPartialBJ(int seq) =>
      'BL.XXXXXX ($seq)'; // BJ partial display
  String _formatTempPartialFW(int seq) =>
      'BC.XXXXXX ($seq)'; // FWIP partial display

  BarangJadiItem _withTempPartialBJIfNeeded(BarangJadiItem item) {
    final already = (item.noBJPartial ?? '').trim().isNotEmpty;
    if (already) return item;

    final code = _formatTempPartialBJ(_nextSeqBJ());
    // require copyWith
    return item.copyWith(noBJPartial: code);
  }

  FurnitureWipItem _withTempPartialFWIfNeeded(FurnitureWipItem item) {
    final already = (item.noFurnitureWIPPartial ?? '').trim().isNotEmpty;
    if (already) return item;

    final code = _formatTempPartialFW(_nextSeqFW());
    return item.copyWith(noFurnitureWIPPartial: code);
  }

  bool _rowIsPartial(Map<String, dynamic> row, PrefixType t) {
    const candKeys = [
      'IsPartial',
      'isPartial',
      'IsPartialRow',
      'isPartialRow'
    ];
    for (final k in candKeys) {
      final v = row[k];
      if (v is bool && v) return true;
      if (v is num && v != 0) return true;
      if (v is String && (v == '1' || v.toLowerCase() == 'true')) return true;
    }

    final bjPart =
    (row['NoBJPartial'] ?? row['noBJPartial'] ?? '').toString().trim();
    if (bjPart.isNotEmpty) return true;

    final fwPart = (row['NoFurnitureWIPPartial'] ??
        row['noFurnitureWIPPartial'] ??
        '')
        .toString()
        .trim();
    if (fwPart.isNotEmpty) return true;

    return false;
  }

  // ---------------------------------------------------------------------------
  // Commit picked → TEMP (FIX KEY MAPPING)
  // ---------------------------------------------------------------------------
  TempCommitResult commitPickedToTemp({required String noBJSortir}) {
    final ctx = lastLookup;
    if (ctx == null || _pickedRows.isEmpty) {
      return const TempCommitResult(0, 0);
    }

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

      // ✅ INI YANG DIPAKAI UI disable
      final simpleKey = ctx.simpleKey(rawRow).trim();

      // ✅ TEMP-only duplicate check
      if (_tempKeys.contains(simpleKey)) {
        skipped++;
        continue;
      }

      final bool isPartial = _rowIsPartial(rawRow, ctx.prefixType);

      bool itemAdded = false;

      if (item is BarangJadiItem) {
        final newItem = isPartial ? _withTempPartialBJIfNeeded(item) : item;

        if ((newItem.noBJPartial ?? '').trim().isNotEmpty) {
          tempBarangJadiPartial.add(newItem);
        } else {
          tempBarangJadi.add(newItem);
        }

        // ✅ track mapping: item -> simpleKey
        final pk = _payloadKeyFromBarangJadiItem(newItem);
        _tempItemToSimpleKey[pk] = simpleKey;

        itemAdded = true;

        final code = _getItemLabelCode(newItem);
        if (code != null && code.trim().isNotEmpty) {
          affectedLabels.add(_normLabel(code));
        }
      } else if (item is FurnitureWipItem) {
        final newItem = isPartial ? _withTempPartialFWIfNeeded(item) : item;

        if ((newItem.noFurnitureWIPPartial ?? '').trim().isNotEmpty) {
          tempFurnitureWipPartial.add(newItem);
        } else {
          tempFurnitureWip.add(newItem);
        }

        final pk = _payloadKeyFromFurnitureWipItem(newItem);
        _tempItemToSimpleKey[pk] = simpleKey;

        itemAdded = true;

        final code = _getItemLabelCode(newItem);
        if (code != null && code.trim().isNotEmpty) {
          affectedLabels.add(_normLabel(code));
        }
      } else {
        skipped++;
        continue;
      }

      if (itemAdded) {
        // ✅ INI yang bikin disable (harus dibersihkan saat delete)
        _tempKeys.add(simpleKey);
        added++;
      } else {
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

  // ---------------------------------------------------------------------------
  // Cabinet Material TEMP (manual from master dropdown)
  // ---------------------------------------------------------------------------
  void addTempCabinetMaterialFromMaster({
    required CabinetMaterialItem masterItem,
    required num Jumlah,
  }) {
    final id = masterItem.IdCabinetMaterial ?? 0;
    if (id <= 0) {
      _d('⚠️ addTempCabinetMaterialFromMaster: IdCabinetMaterial invalid');
      return;
    }

    final idx =
    tempCabinetMaterial.indexWhere((x) => (x.IdCabinetMaterial ?? 0) == id);
    if (idx >= 0) {
      final old = tempCabinetMaterial[idx];
      tempCabinetMaterial[idx] = old.copyWith(Jumlah: Jumlah);
      _d('✅ Updated existing material temp: ${tempCabinetMaterial[idx].toDebugString()}');
      notifyListeners();
      return;
    }

    final newItem = masterItem.copyWith(Jumlah: Jumlah);
    tempCabinetMaterial.add(newItem);

    _d('✅ Added cabinet material to temp: ${newItem.toDebugString()}');
    notifyListeners();
  }

  void updateTempCabinetMaterialJumlah({
    required int IdCabinetMaterial,
    required num Jumlah,
  }) {
    final idx = tempCabinetMaterial
        .indexWhere((x) => (x.IdCabinetMaterial ?? 0) == IdCabinetMaterial);
    if (idx == -1) return;

    final old = tempCabinetMaterial[idx];
    tempCabinetMaterial[idx] = old.copyWith(Jumlah: Jumlah);

    _d('✅ Updated cabinet material temp: ${tempCabinetMaterial[idx].toDebugString()}');
    notifyListeners();
  }

  bool hasCabinetMaterialInTemp(int IdCabinetMaterial) {
    return tempCabinetMaterial
        .any((x) => (x.IdCabinetMaterial ?? 0) == IdCabinetMaterial);
  }

  // ---------------------------------------------------------------------------
  // Delete temp items (FIX: remove _tempKeys pakai mapping item->simpleKey)
  // ---------------------------------------------------------------------------
  bool deleteIfTemp(dynamic item) {
    bool ok = false;

    if (item is BarangJadiItem) {
      ok = tempBarangJadi.remove(item) || tempBarangJadiPartial.remove(item);

      if (ok) {
        final pk = _payloadKeyFromBarangJadiItem(item);
        final sk = _tempItemToSimpleKey.remove(pk);
        if (sk != null) _tempKeys.remove(sk);
      }
    } else if (item is FurnitureWipItem) {
      ok = tempFurnitureWip.remove(item) ||
          tempFurnitureWipPartial.remove(item);

      if (ok) {
        final pk = _payloadKeyFromFurnitureWipItem(item);
        final sk = _tempItemToSimpleKey.remove(pk);
        if (sk != null) _tempKeys.remove(sk);
      }
    } else if (item is CabinetMaterialItem) {
      ok = tempCabinetMaterial.remove(item);
      // material tidak ikut _tempKeys karena _tempKeys hanya untuk lookup rows
    }

    if (ok) {
      final label = _getItemLabelCode(item);
      if (label != null) _updateTempItemsByLabel(label);

      debugDumpTempLists(tag: 'after deleteIfTemp');
      debugDumpTempByLabel();
      debugDumpTempKeys(tag: 'after deleteIfTemp');

      notifyListeners();
    }

    return ok;
  }

  void clearAllTempItems() {
    tempBarangJadi.clear();
    tempBarangJadiPartial.clear();
    tempFurnitureWip.clear();
    tempFurnitureWipPartial.clear();
    tempCabinetMaterial.clear();

    _tempKeys.clear();
    _tempItemToSimpleKey.clear();
    _tempItemsByLabel.clear();
    clearPicks();

    _tempPartialSeqBJ = 0;
    _tempPartialSeqFW = 0;

    _d('clearAllTempItems() called');
    debugDumpTempLists(tag: 'after clearAllTempItems');
    debugDumpTempByLabel();
    debugDumpTempKeys(tag: 'after clearAllTempItems');

    notifyListeners();
  }

  int deleteAllTempForLabel(String labelCode) {
    final code = _normLabel(labelCode);
    if (code.isEmpty) return 0;

    final bucket = getTemporaryDataForLabel(code);
    if (bucket == null || bucket.isEmpty) return 0;

    final items = List<dynamic>.from(bucket.allItems);

    int removed = 0;
    for (final it in items) {
      if (deleteIfTemp(it)) removed++;
    }

    _updateTempItemsByLabel(code);
    notifyListeners();
    return removed;
  }

  int get totalTempCount =>
      tempBarangJadi.length +
          tempBarangJadiPartial.length +
          tempFurnitureWip.length +
          tempFurnitureWipPartial.length +
          tempCabinetMaterial.length;

  // ---------------------------------------------------------------------------
  // Submit temp items
  // ---------------------------------------------------------------------------
  bool isSubmitting = false;
  String? submitError;

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{};

    if (tempBarangJadi.isNotEmpty) {
      payload['barangJadi'] =
          tempBarangJadi.map((e) => {'noBJ': e.noBJ}).toList();
    }

    if (tempBarangJadiPartial.isNotEmpty) {
      payload['barangJadiPartial'] = tempBarangJadiPartial
          .map((e) => {
        'noBJ': e.noBJ,
        'pcs': e.pcs,
      })
          .toList();
    }

    if (tempFurnitureWip.isNotEmpty) {
      payload['furnitureWip'] = tempFurnitureWip
          .map((e) => {'noFurnitureWIP': e.noFurnitureWIP})
          .toList();
    }

    if (tempFurnitureWipPartial.isNotEmpty) {
      payload['furnitureWipPartial'] = tempFurnitureWipPartial
          .map((e) => {
        'noFurnitureWIP': e.noFurnitureWIP,
        'pcs': e.pcs,
      })
          .toList();
    }

    if (tempCabinetMaterial.isNotEmpty) {
      payload['cabinetMaterial'] = tempCabinetMaterial
          .map((e) => {
        'idCabinetMaterial': e.IdCabinetMaterial,
        'jumlah': e.Jumlah,
      })
          .toList();
    }

    return payload;
  }

  Future<bool> submitTempItems(String noBJSortir) async {
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
      _d('Submitting temp items to $noBJSortir');
      _d('Payload: ${json.encode(payload)}');

      // ✅ IMPORTANT: Sortir Reject pakai submitInputs (sama seperti BJJual submitInputsAndPartials)
      final response = await repository.submitInputs(noBJSortir, payload);
      _d('Submit response: ${json.encode(response)}');

      final success = response['success'] as bool? ?? false;
      if (!success) {
        submitError = (response['message'] as String?) ?? 'Submit gagal';
        return false;
      }

      clearAllTempItems();
      clearLookupCache();
      clearInputsCache(noBJSortir);
      await loadInputs(noBJSortir, force: true);

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
    if (tempBarangJadi.isNotEmpty) {
      parts.add('${tempBarangJadi.length} BJ (full)');
    }
    if (tempBarangJadiPartial.isNotEmpty) {
      parts.add('${tempBarangJadiPartial.length} BJ Partial');
    }
    if (tempFurnitureWip.isNotEmpty) {
      parts.add('${tempFurnitureWip.length} FWIP (full)');
    }
    if (tempFurnitureWipPartial.isNotEmpty) {
      parts.add('${tempFurnitureWipPartial.length} FWIP Partial');
    }
    if (tempCabinetMaterial.isNotEmpty) {
      parts.add('${tempCabinetMaterial.length} Cabinet Material');
    }

    return 'Total $totalTempCount items:\n${parts.join(', ')}';
  }

  // ---------------------------------------------------------------------------
  // Delete inputs & partials (DB items)
  // ---------------------------------------------------------------------------
  bool isDeleting = false;
  String? deleteError;
  Map<String, dynamic>? lastDeleteResult;

  Map<String, dynamic> _buildDeletePayloadFromItems(List<dynamic> items) {
    final payload = <String, dynamic>{};

    void add(String key, Map<String, dynamic> row) {
      final list =
      (payload[key] ?? <Map<String, dynamic>>[]) as List<Map<String, dynamic>>;
      list.add(row);
      payload[key] = list;
    }

    for (final it in items) {
      if (it is BarangJadiItem) {
        final isPart = (it.noBJPartial ?? '').trim().isNotEmpty;
        if (isPart) {
          add('barangJadiPartial', {'noBJPartial': it.noBJPartial});
        } else {
          add('barangJadi', {'noBJ': it.noBJ});
        }
      } else if (it is FurnitureWipItem) {
        final isPart = (it.noFurnitureWIPPartial ?? '').trim().isNotEmpty;
        if (isPart) {
          final code = (it.noFurnitureWIPPartial ?? '').trim();
          if (code.isNotEmpty) {
            add('furnitureWipPartial', {'noFurnitureWipPartial': code});
          }
        } else {
          add('furnitureWip', {'noFurnitureWIP': it.noFurnitureWIP});
        }
      } else if (it is CabinetMaterialItem) {
        add('cabinetMaterial', {'idCabinetMaterial': it.IdCabinetMaterial});
      }
    }

    return payload;
  }

  Future<bool> deleteItems(String noBJSortir, List<dynamic> items) async {
    if (items.isEmpty) {
      deleteError = 'Tidak ada data yang dipilih untuk dihapus';
      notifyListeners();
      return false;
    }

    // 1) hapus yang TEMP dulu
    final List<dynamic> dbItems = [];
    for (final it in items) {
      final removedFromTemp = deleteIfTemp(it);
      if (!removedFromTemp) dbItems.add(it);
    }

    // kalau semuanya TEMP -> selesai
    if (dbItems.isEmpty) {
      _d('deleteItems: hanya menghapus TEMP, tidak call API');
      notifyListeners();
      return true;
    }

    // 2) build payload DB delete
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
      _d('deleteItems: calling deleteInputs for $noBJSortir');
      _d('Delete payload: ${json.encode(payload)}');

      // ✅ IMPORTANT: Sortir Reject pakai deleteInputs (sama seperti BJJual deleteInputsAndPartials)
      final res = await repository.deleteInputs(noBJSortir, payload);
      lastDeleteResult = res;

      final success = res['success'] == true;
      final message = res['message'] as String? ?? '';

      _d('Delete response: ${json.encode(res)}');

      if (!success) {
        deleteError = message.isEmpty ? 'Gagal menghapus data' : message;
        return false;
      }

      clearInputsCache(noBJSortir);
      await loadInputs(noBJSortir, force: true);

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
}