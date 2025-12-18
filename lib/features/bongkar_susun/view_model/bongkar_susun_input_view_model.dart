// lib/features/shared/bongkar_susun/view_model/bongkar_susun_input_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../production/shared/models/barang_jadi_item.dart';
import '../../production/shared/models/bb_item.dart';
import '../../production/shared/models/bonggolan_item.dart';
import '../../production/shared/models/broker_item.dart';
import '../../production/shared/models/crusher_item.dart';
import '../../production/shared/models/furniture_wip_item.dart';
import '../../production/shared/models/gilingan_item.dart';
import '../../production/shared/models/mixer_item.dart';
import '../../production/shared/models/washing_item.dart';
import '../repository/bongkar_susun_input_repository.dart';
import '../model/bongkar_susun_inputs_model.dart';
import '../../production/shared/models/production_label_lookup_result.dart';

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
  final List<BbItem> bbItems;
  final List<BbItem> bbPartials;
  final List<WashingItem> washingItems;
  final List<CrusherItem> crusherItems;
  final List<GilinganItem> gilinganItems;
  final List<GilinganItem> gilinganPartials;
  final List<MixerItem> mixerItems;
  final List<MixerItem> mixerPartials;
  final List<BonggolanItem> bonggolanItems;
  final List<FurnitureWipItem> furnitureWipItems;
  final List<FurnitureWipItem> furnitureWipPartials;
  final List<BarangJadiItem> barangJadiItems;
  final List<BarangJadiItem> barangJadiPartials;
  final DateTime addedAt;

  TempItemsByLabel({
    required this.labelCode,
    this.brokerItems = const [],
    this.brokerPartials = const [],
    this.bbItems = const [],
    this.bbPartials = const [],
    this.washingItems = const [],
    this.crusherItems = const [],
    this.gilinganItems = const [],
    this.gilinganPartials = const [],
    this.mixerItems = const [],
    this.mixerPartials = const [],
    this.bonggolanItems = const [],
    this.furnitureWipItems = const [],
    this.furnitureWipPartials = const [],
    this.barangJadiItems = const [],
    this.barangJadiPartials = const [],
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  int get totalCount =>
      brokerItems.length +
          brokerPartials.length +
          bbItems.length +
          bbPartials.length +
          washingItems.length +
          crusherItems.length +
          gilinganItems.length +
          gilinganPartials.length +
          mixerItems.length +
          mixerPartials.length +
          bonggolanItems.length +
          furnitureWipItems.length +
          furnitureWipPartials.length +
          barangJadiItems.length +
          barangJadiPartials.length;

  bool get isEmpty => totalCount == 0;

  List<dynamic> get allItems => [
    ...brokerItems,
    ...brokerPartials,
    ...bbItems,
    ...bbPartials,
    ...washingItems,
    ...crusherItems,
    ...gilinganItems,
    ...gilinganPartials,
    ...mixerItems,
    ...mixerPartials,
    ...bonggolanItems,
    ...furnitureWipItems,
    ...furnitureWipPartials,
    ...barangJadiItems,
    ...barangJadiPartials,
  ];
}

// -----------------------------------------------------------------------------
// ViewModel
// -----------------------------------------------------------------------------
class BongkarSusunInputViewModel extends ChangeNotifier {
  final BongkarSusunInputRepository repository;
  BongkarSusunInputViewModel({required this.repository});

  // ---------------------------------------------------------------------------
  // Debug control (single switch)
  // ---------------------------------------------------------------------------
  static const bool _verbose = true;
  void _d(String message) {
    if (kDebugMode && _verbose) debugPrint('[BongkarSusunInputVM] $message');
  }

  // ---------- DEBUG HELPERS ----------
  String _nn(Object? v) =>
      (v == null || (v is String && v.trim().isEmpty)) ? '-' : v.toString();
  String _kg(num? v) =>
      v == null ? '-' : (v is int ? '$v' : v.toStringAsFixed(2));
  String _pcs(num? v) => v == null ? '-' : v.toString();

  String _labelOf(dynamic it) => _getItemLabelCode(it) ?? '-';

  String displayTitleOf(dynamic it) {
    if (it is BrokerItem) {
      return (it.noBrokerPartial ?? '').trim().isNotEmpty
          ? it.noBrokerPartial!
          : _nn(it.noBroker);
    }
    if (it is BbItem) {
      return (it.noBBPartial ?? '').trim().isNotEmpty
          ? it.noBBPartial!
          : _bbTitleKeyFrom(it);
    }
    if (it is GilinganItem) {
      return (it.noGilinganPartial ?? '').trim().isNotEmpty
          ? it.noGilinganPartial!
          : _nn(it.noGilingan);
    }
    if (it is MixerItem) {
      return (it.noMixerPartial ?? '').trim().isNotEmpty
          ? it.noMixerPartial!
          : _nn(it.noMixer);
    }

    // ✅ TAMBAHKAN: FurnitureWipItem
    if (it is FurnitureWipItem) {
      return (it.noFurnitureWIPPartial ?? '').trim().isNotEmpty
          ? it.noFurnitureWIPPartial!
          : _nn(it.noFurnitureWIP);
    }

    // ✅ TAMBAHKAN: BarangJadiItem
    if (it is BarangJadiItem) {
      return (it.noBJPartial ?? '').trim().isNotEmpty
          ? it.noBJPartial!
          : _nn(it.noBJ);
    }

    if (it is WashingItem) return _nn(it.noWashing);
    if (it is CrusherItem) return _nn(it.noCrusher);
    if (it is BonggolanItem) return _nn(it.noBonggolan);
    return '-';
  }

  String _bbTitleKeyFrom(BbItem e) {
    final part = (e.noBBPartial ?? '').trim();
    if (part.isNotEmpty) return part;
    final nb = (e.noBahanBaku ?? '').trim();
    final np = e.noPallet;
    final hasNb = nb.isNotEmpty;
    final hasNp = (np != null && np > 0);
    if (!hasNb && !hasNp) return '-';
    if (hasNb && hasNp) return '$nb-$np';
    if (hasNb) return nb;
    return 'Pallet $np';
  }

  String _fmtItem(dynamic it) {
    final t = displayTitleOf(it);

    if (it is BrokerItem) {
      final isPart = (it.noBrokerPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[BROKER•PART] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg'
          : '[BROKER] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg';
    }
    if (it is BbItem) {
      final isPart = (it.noBBPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[BB•PART] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg'
          : '[BB] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg';
    }
    if (it is WashingItem) {
      return '[WASH] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg';
    }
    if (it is CrusherItem) {
      return '[CRUSH] $t • ${_kg(it.berat)}kg';
    }
    if (it is GilinganItem) {
      final isPart = (it.noGilinganPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[GIL•PART] $t • ${_kg(it.berat)}kg'
          : '[GIL] $t • ${_kg(it.berat)}kg';
    }
    if (it is MixerItem) {
      final isPart = (it.noMixerPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[MIX•PART] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg'
          : '[MIX] $t • sak ${_nn(it.noSak)} • ${_kg(it.berat)}kg';
    }
    if (it is BonggolanItem) {
      return '[BONGGOLAN] $t • ${_kg(it.berat)}kg';
    }

    // ✅ TAMBAHKAN: FurnitureWipItem
    if (it is FurnitureWipItem) {
      final isPart = (it.noFurnitureWIPPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[FW•PART] $t • ${_pcs(it.pcs)} pcs • ${_kg(it.berat)}kg'
          : '[FW] $t • ${_pcs(it.pcs)} pcs • ${_kg(it.berat)}kg';
    }

    // ✅ TAMBAHKAN: BarangJadiItem
    if (it is BarangJadiItem) {
      final isPart = (it.noBJPartial ?? '').trim().isNotEmpty;
      return isPart
          ? '[BJ•PART] $t • ${_pcs(it.pcs)} pcs • ${_kg(it.berat)}kg'
          : '[BJ] $t • ${_pcs(it.pcs)} pcs • ${_kg(it.berat)}kg';
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
    _dumpList('tempBb', tempBb, _keyFromBbItem);
    _dumpList('tempBbPartial', tempBbPartial, _keyFromBbItem);
    _dumpList('tempWashing', tempWashing, _keyFromWashingItem);
    _dumpList('tempCrusher', tempCrusher, _keyFromCrusherItem);
    _dumpList('tempGilingan', tempGilingan, _keyFromGilinganItem);
    _dumpList('tempGilinganPartial', tempGilinganPartial, _keyFromGilinganItem);
    _dumpList('tempMixer', tempMixer, _keyFromMixerItem);
    _dumpList('tempMixerPartial', tempMixerPartial, _keyFromMixerItem);
    _dumpList('tempBonggolan', tempBonggolan, _keyFromBonggolanItem);
    _dumpList('tempFurnitureWip', tempFurnitureWip, _keyFromFurnitureWipItem);
    _dumpList('tempFurnitureWipPartial', tempFurnitureWipPartial,
        _keyFromFurnitureWipItem);
    _dumpList('tempBarangJadi', tempBarangJadi, _keyFromBarangJadiItem);
    _dumpList(
        'tempBarangJadiPartial', tempBarangJadiPartial, _keyFromBarangJadiItem);
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
  // Inputs cache (per NoBongkarSusun)
  // ---------------------------------------------------------------------------
  final Map<String, BongkarSusunInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noBongkarSusun) =>
      _inputsLoading[noBongkarSusun] == true;
  String? inputsError(String noBongkarSusun) => _inputsError[noBongkarSusun];
  BongkarSusunInputs? inputsOf(String noBongkarSusun) =>
      _inputsCache[noBongkarSusun];
  int inputsCount(String noBongkarSusun, String key) =>
      _inputsCache[noBongkarSusun]?.summary[key] ?? 0;

  // Prevent duplicate per-row inputs fetch
  final Map<String, Future<BongkarSusunInputs>> _inflight = {};

  Future<BongkarSusunInputs?> loadInputs(String noBongkarSusun,
      {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noBongkarSusun)) {
      return _inputsCache[noBongkarSusun];
    }
    if (!force && _inflight.containsKey(noBongkarSusun)) {
      try {
        return await _inflight[noBongkarSusun];
      } catch (_) {}
    }

    _inputsLoading[noBongkarSusun] = true;
    _inputsError[noBongkarSusun] = null;
    notifyListeners();

    final future = repository.fetchInputs(noBongkarSusun, force: force);
    _inflight[noBongkarSusun] = future;

    try {
      final result = await future;
      _inputsCache[noBongkarSusun] = result;
      return result;
    } catch (e) {
      _inputsError[noBongkarSusun] = e.toString();
      return null;
    } finally {
      _inflight.remove(noBongkarSusun);
      _inputsLoading[noBongkarSusun] = false;
      notifyListeners();
    }
  }

  void clearInputsCache([String? noBongkarSusun]) {
    if (noBongkarSusun == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      _inputsCache.remove(noBongkarSusun);
      _inputsLoading.remove(noBongkarSusun);
      _inputsError.remove(noBongkarSusun);
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

  Future<ProductionLabelLookupResult?> lookupLabel(String code,
      {bool force = false}) async {
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
    if (t.brokerPartials.isNotEmpty) {
      s.add('${t.brokerPartials.length} Broker Partial');
    }
    if (t.bbItems.isNotEmpty) s.add('${t.bbItems.length} Bahan Baku (full)');
    if (t.bbPartials.isNotEmpty) s.add('${t.bbPartials.length} BB Partial');
    if (t.washingItems.isNotEmpty) s.add('${t.washingItems.length} Washing');
    if (t.crusherItems.isNotEmpty) s.add('${t.crusherItems.length} Crusher');
    if (t.gilinganItems.isNotEmpty) {
      s.add('${t.gilinganItems.length} Gilingan (full)');
    }
    if (t.gilinganPartials.isNotEmpty) {
      s.add('${t.gilinganPartials.length} Gilingan Partial');
    }
    if (t.mixerItems.isNotEmpty) s.add('${t.mixerItems.length} Mixer (full)');
    if (t.mixerPartials.isNotEmpty) {
      s.add('${t.mixerPartials.length} Mixer Partial');
    }
    if (t.bonggolanItems.isNotEmpty) {
      s.add('${t.bonggolanItems.length} Bonggolan');
    }
    if (t.furnitureWipItems.isNotEmpty) {
      s.add('${t.furnitureWipItems.length} Furniture WIP (full)');
    }
    if (t.furnitureWipPartials.isNotEmpty) {
      s.add('${t.furnitureWipPartials.length} Furniture WIP Partial');
    }
    if (t.barangJadiItems.isNotEmpty) {
      s.add('${t.barangJadiItems.length} Barang Jadi (full)');
    }
    if (t.barangJadiPartials.isNotEmpty) {
      s.add('${t.barangJadiPartials.length} Barang Jadi Partial');
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
    final trimmed = labelCode.trim();
    final t = _tempItemsByLabel[trimmed];
    if (t == null) return;

    for (final item in itemsToRemove) {
      if (item is BrokerItem) {
        tempBroker.remove(item);
        tempBrokerPartial.remove(item);
        _tempKeys.remove(_keyFromBrokerItem(item));
      } else if (item is BbItem) {
        tempBb.remove(item);
        tempBbPartial.remove(item);
        _tempKeys.remove(_keyFromBbItem(item));
      } else if (item is WashingItem) {
        tempWashing.remove(item);
        _tempKeys.remove(_keyFromWashingItem(item));
      } else if (item is CrusherItem) {
        tempCrusher.remove(item);
        _tempKeys.remove(_keyFromCrusherItem(item));
      } else if (item is GilinganItem) {
        tempGilingan.remove(item);
        tempGilinganPartial.remove(item);
        _tempKeys.remove(_keyFromGilinganItem(item));
      } else if (item is MixerItem) {
        tempMixer.remove(item);
        tempMixerPartial.remove(item);
        _tempKeys.remove(_keyFromMixerItem(item));
      } else if (item is BonggolanItem) {
        tempBonggolan.remove(item);
        _tempKeys.remove(_keyFromBonggolanItem(item));
      } else if (item is FurnitureWipItem) {
        tempFurnitureWip.remove(item);
        tempFurnitureWipPartial.remove(item);
        _tempKeys.remove(_keyFromFurnitureWipItem(item));
      } else if (item is BarangJadiItem) {
        tempBarangJadi.remove(item);
        tempBarangJadiPartial.remove(item);
        _tempKeys.remove(_keyFromBarangJadiItem(item));
      }
    }

    _updateTempItemsByLabel(trimmed);
    notifyListeners();
  }

  void _updateTempItemsByLabel(String labelCode) {
    final code = labelCode.trim();

    final brokerFull =
    tempBroker.where((e) => _getItemLabelCode(e) == code).toList();
    final brokerPart =
    tempBrokerPartial.where((e) => _getItemLabelCode(e) == code).toList();

    final bbFull = tempBb.where((e) => _getItemLabelCode(e) == code).toList();
    final bbPart =
    tempBbPartial.where((e) => _getItemLabelCode(e) == code).toList();

    final washingItems =
    tempWashing.where((e) => _getItemLabelCode(e) == code).toList();
    final crusherItems =
    tempCrusher.where((e) => _getItemLabelCode(e) == code).toList();

    final gilFull =
    tempGilingan.where((e) => _getItemLabelCode(e) == code).toList();
    final gilPart =
    tempGilinganPartial.where((e) => _getItemLabelCode(e) == code).toList();

    final mixFull =
    tempMixer.where((e) => _getItemLabelCode(e) == code).toList();
    final mixPart =
    tempMixerPartial.where((e) => _getItemLabelCode(e) == code).toList();

    final bonggolanItems =
    tempBonggolan.where((e) => _getItemLabelCode(e) == code).toList();

    final fwFull =
    tempFurnitureWip.where((e) => _getItemLabelCode(e) == code).toList();
    final fwPart = tempFurnitureWipPartial
        .where((e) => _getItemLabelCode(e) == code)
        .toList();

    final bjFull =
    tempBarangJadi.where((e) => _getItemLabelCode(e) == code).toList();
    final bjPart = tempBarangJadiPartial
        .where((e) => _getItemLabelCode(e) == code)
        .toList();

    if ([
      brokerFull,
      brokerPart,
      bbFull,
      bbPart,
      washingItems,
      crusherItems,
      gilFull,
      gilPart,
      mixFull,
      mixPart,
      bonggolanItems,
      fwFull,
      fwPart,
      bjFull,
      bjPart
    ].every((l) => l.isEmpty)) {
      _tempItemsByLabel.remove(code);
      return;
    }

    _tempItemsByLabel[code] = TempItemsByLabel(
      labelCode: code,
      brokerItems: brokerFull,
      brokerPartials: brokerPart,
      bbItems: bbFull,
      bbPartials: bbPart,
      washingItems: washingItems,
      crusherItems: crusherItems,
      gilinganItems: gilFull,
      gilinganPartials: gilPart,
      mixerItems: mixFull,
      mixerPartials: mixPart,
      bonggolanItems: bonggolanItems,
      furnitureWipItems: fwFull,
      furnitureWipPartials: fwPart,
      barangJadiItems: bjFull,
      barangJadiPartials: bjPart,
      addedAt: _tempItemsByLabel[code]?.addedAt ?? DateTime.now(),
    );
  }

  String? _getItemLabelCode(dynamic item) {
    if (item is BrokerItem) {
      final part = (item.noBrokerPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return item.noBroker;
    }

    if (item is BbItem) {
      final part = (item.noBBPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      final noBb = (item.noBahanBaku ?? '').trim();
      final noPallet = item.noPallet;
      if (noPallet == null || noPallet == 0) return noBb;
      return '$noBb-$noPallet';
    }

    if (item is WashingItem) return item.noWashing;

    if (item is CrusherItem) return item.noCrusher;

    if (item is GilinganItem) {
      final part = (item.noGilinganPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return item.noGilingan;
    }

    if (item is MixerItem) {
      final part = (item.noMixerPartial ?? '').trim();
      if (part.isNotEmpty) return part;
      return item.noMixer;
    }

    if (item is BonggolanItem) return item.noBonggolan;

    // ✅ TAMBAHKAN: FurnitureWipItem
    if (item is FurnitureWipItem) {
      final part = (item.noFurnitureWIPPartial ?? '').trim();
      if (part.isNotEmpty) return part;  // BC.XXXXXXXXXX
      return item.noFurnitureWIP;         // BB.0000044512
    }

    // ✅ TAMBAHKAN: BarangJadiItem
    if (item is BarangJadiItem) {
      final part = (item.noBJPartial ?? '').trim();
      if (part.isNotEmpty) return part;  // BL.XXXXXXXXXX
      return item.noBJ;                   // BA.XXXXXXXXXX
    }

    return null;
  }
  // ---------------------------------------------------------------------------
  // Temp selections (anti-duplicate)
  // ---------------------------------------------------------------------------
  final List<BrokerItem> tempBroker = [];
  final List<BrokerItem> tempBrokerPartial = [];

  final List<BbItem> tempBb = [];
  final List<BbItem> tempBbPartial = [];

  final List<WashingItem> tempWashing = [];
  final List<CrusherItem> tempCrusher = [];

  final List<GilinganItem> tempGilingan = [];
  final List<GilinganItem> tempGilinganPartial = [];

  final List<MixerItem> tempMixer = [];
  final List<MixerItem> tempMixerPartial = [];

  final List<BonggolanItem> tempBonggolan = [];

  final List<FurnitureWipItem> tempFurnitureWip = [];
  final List<FurnitureWipItem> tempFurnitureWipPartial = [];

  final List<BarangJadiItem> tempBarangJadi = [];
  final List<BarangJadiItem> tempBarangJadiPartial = [];

  final Set<String> _pickedKeys = <String>{};
  final List<Map<String, dynamic>> _pickedRows = <Map<String, dynamic>>[];
  final Map<String, int> _keyToRowIndex = {};

  // Keys we manage
  final Set<String> _tempKeys = <String>{};

  // ====== key builders ======
  String _keyFromBrokerItem(BrokerItem i) =>
      'D.|Broker_d|${i.noBroker ?? '-'}|${(i.noSak ?? '').toString().trim()}';
  String _keyFromBbItem(BbItem i) {
    final noBB = i.noBahanBaku ?? '-';
    final noSak = (i.noSak ?? '').toString().trim();
    final noPallet = i.noPallet ?? 0;
    return 'A.|BahanBaku_d|$noBB|$noPallet|$noSak';
  }

  String _keyFromWashingItem(WashingItem i) =>
      'B.|Washing_d|${i.noWashing ?? '-'}|${(i.noSak ?? '').toString().trim()}';
  String _keyFromCrusherItem(CrusherItem i) =>
      'F.|Crusher|${i.noCrusher ?? '-'}|';
  String _keyFromGilinganItem(GilinganItem i) =>
      'V.|Gilingan|${i.noGilingan ?? '-'}|';
  String _keyFromMixerItem(MixerItem i) =>
      'H.|Mixer_d|${i.noMixer ?? '-'}|${(i.noSak ?? '').toString().trim()}';
  String _keyFromBonggolanItem(BonggolanItem i) =>
      'M.|Bonggolan|${i.noBonggolan ?? '-'}|';
  String _keyFromFurnitureWipItem(FurnitureWipItem i) =>
      'BB.|FurnitureWIP|${i.noFurnitureWIP ?? '-'}|';
  String _keyFromBarangJadiItem(BarangJadiItem i) =>
      'BA.|BarangJadi|${i.noBJ ?? '-'}|';

  // ====== keys in DB (from cache) ======
  Set<String> _dbKeysFor(String noBongkarSusun) {
    final keys = <String>{};
    final db = _inputsCache[noBongkarSusun];
    if (db != null) {
      for (final x in db.broker) keys.add(_keyFromBrokerItem(x));
      for (final x in db.bb) keys.add(_keyFromBbItem(x));
      for (final x in db.washing) keys.add(_keyFromWashingItem(x));
      for (final x in db.crusher) keys.add(_keyFromCrusherItem(x));
      for (final x in db.gilingan) keys.add(_keyFromGilinganItem(x));
      for (final x in db.mixer) keys.add(_keyFromMixerItem(x));
      for (final x in db.bonggolan) keys.add(_keyFromBonggolanItem(x));
      for (final x in db.furnitureWip) keys.add(_keyFromFurnitureWipItem(x));
      for (final x in db.barangJadi) keys.add(_keyFromBarangJadiItem(x));
    }
    return keys;
  }

  // ====== DB + TEMP ======
  Set<String> _allKeysFor(String noBongkarSusun) {
    final all = _dbKeysFor(noBongkarSusun);
    all.addAll(_tempKeys);
    return all;
  }

  // ====== PUBLIC API (TEMP-only duplicate checks) ======
  bool isRowAlreadyPresent(Map<String, dynamic> row, String noBongkarSusun) {
    final ctx = lastLookup;
    if (ctx == null) return false;
    final simpleKey = ctx.simpleKey(row);
    return _tempKeys.contains(simpleKey);
  }

  int countNewRowsInLastLookup(String noBongkarSusun) {
    final ctx = lastLookup;
    if (ctx == null) return 0;
    return ctx.data.where((r) => !_tempKeys.contains(ctx.simpleKey(r))).length;
  }

  bool willBeDuplicate(Map<String, dynamic> row, String noBongkarSusun) {
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

  void pickAllNew(String noBongkarSusun) {
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
    final candKeys = const [
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
    switch (t) {
      case PrefixType.broker:
        final s = (row['NoBrokerPartial'] ?? row['noBrokerPartial'] ?? '')
            .toString()
            .trim();
        return s.isNotEmpty;
      case PrefixType.bb:
        final s =
        (row['NoBBPartial'] ?? row['noBBPartial'] ?? '').toString().trim();
        return s.isNotEmpty;
      case PrefixType.gilingan:
        final s = (row['NoGilinganPartial'] ?? row['noGilinganPartial'] ?? '')
            .toString()
            .trim();
        return s.isNotEmpty;
      case PrefixType.mixer:
        final s = (row['NoMixerPartial'] ?? row['noMixerPartial'] ?? '')
            .toString()
            .trim();
        return s.isNotEmpty;
      case PrefixType.furnitureWip:
        final s = (row['NoFurnitureWIPPartial'] ??
            row['noFurnitureWIPPartial'] ??
            row['noFurnitureWipPartial'] ??
            '')
            .toString()
            .trim();
        return s.isNotEmpty;
      case PrefixType.barangJadi:
        final s = (row['NoBJPartial'] ??
            row['noBJPartial'] ??
            row['noBjPartial'] ??
            '')
            .toString()
            .trim();
        return s.isNotEmpty;
      default:
        return false;
    }
  }

  TempCommitResult commitPickedToTemp({required String noBongkarSusun}) {
    final ctx = lastLookup;
    if (ctx == null || _pickedRows.isEmpty) {
      return const TempCommitResult(0, 0);
    }

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
          final existingPcs = _getPcsFromItem(existingPartial);
          final newWeight = rawRow['berat'] ?? rawRow['Berat'];
          final newPcs = rawRow['pcs'] ?? rawRow['Pcs'];

          if (existingWeight == newWeight && existingPcs == newPcs) {
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

      final String tempKey = item is BrokerItem
          ? _keyFromBrokerItem(item)
          : item is BbItem
          ? _keyFromBbItem(item)
          : item is WashingItem
          ? _keyFromWashingItem(item)
          : item is CrusherItem
          ? _keyFromCrusherItem(item)
          : item is GilinganItem
          ? _keyFromGilinganItem(item)
          : item is MixerItem
          ? _keyFromMixerItem(item)
          : item is BonggolanItem
          ? _keyFromBonggolanItem(item)
          : item is FurnitureWipItem
          ? _keyFromFurnitureWipItem(item)
          : item is BarangJadiItem
          ? _keyFromBarangJadiItem(item)
          : simpleKey;

      if (!_tempKeys.add(tempKey)) {
        skipped++;
        continue;
      }
      seenTemp.add(simpleKey);

      final newItem =
      _withTempPartialIfNeeded(item, ctx.prefixType, isPartial);

      bool itemAdded = false;
      if (newItem is BrokerItem) {
        if (newItem.isPartialRow) {
          tempBrokerPartial.add(newItem);
        } else {
          tempBroker.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is BbItem) {
        if (newItem.isPartialRow) {
          tempBbPartial.add(newItem);
        } else {
          tempBb.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is GilinganItem) {
        if (newItem.isPartialRow) {
          tempGilinganPartial.add(newItem);
        } else {
          tempGilingan.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is MixerItem) {
        if (newItem.isPartialRow) {
          tempMixerPartial.add(newItem);
        } else {
          tempMixer.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is FurnitureWipItem) {
        if (newItem.isPartialRow) {
          tempFurnitureWipPartial.add(newItem);
        } else {
          tempFurnitureWip.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is BarangJadiItem) {
        if (newItem.isPartialRow) {
          tempBarangJadiPartial.add(newItem);
        } else {
          tempBarangJadi.add(newItem);
        }
        itemAdded = true;
      } else if (newItem is WashingItem) {
        tempWashing.add(newItem);
        itemAdded = true;
      } else if (newItem is CrusherItem) {
        tempCrusher.add(newItem);
        itemAdded = true;
      } else if (newItem is BonggolanItem) {
        tempBonggolan.add(newItem);
        itemAdded = true;
      } else if (newItem is FurnitureWipItem) {
        if (newItem.isPartialRow) { tempFurnitureWipPartial.add(newItem); }
        else { tempFurnitureWip.add(newItem); }
        itemAdded = true;
      } else if (newItem is BarangJadiItem) {
        if (newItem.isPartialRow) { tempBarangJadiPartial.add(newItem); }
        else { tempBarangJadi.add(newItem); }
        itemAdded = true;
      }

      if (itemAdded) {
        final code = _getItemLabelCode(newItem);
        if (code != null && code.trim().isNotEmpty) {
          affectedLabels.add(code.trim());
        }
        added++;
      } else {
        _tempKeys.remove(tempKey);
        skipped++;
      }
    }

    for (final label in affectedLabels) {
      _updateTempItemsByLabel(label);
    }

    debugDumpTempLists(tag: 'after commitPickedToTemp (TEMP-only dedup)');
    debugDumpTempByLabel();
    debugDumpTempKeys(tag: 'after commit');

    clearPicks();
    notifyListeners();
    return TempCommitResult(added, skipped);
  }

  // Helper methods baru untuk cek partial
  String _getBaseKeyWithoutWeight(Map<String, dynamic> row, PrefixType type) {
    switch (type) {
      case PrefixType.broker:
        final noBroker = row['NoBroker'] ?? row['noBroker'] ?? '';
        final noSak = row['NoSak'] ?? row['noSak'] ?? '';
        return 'D.|Broker_d|$noBroker|$noSak';
      case PrefixType.bb:
        final noBb = row['NoBahanBaku'] ?? row['noBahanBaku'] ?? '';
        final noPallet = row['NoPallet'] ?? row['noPallet'] ?? 0;
        final noSak = row['NoSak'] ?? row['noSak'] ?? '';
        return 'A.|BahanBaku_d|$noBb|$noPallet|$noSak';
      case PrefixType.gilingan:
        final noGil = row['NoGilingan'] ?? row['noGilingan'] ?? '';
        return 'V.|Gilingan|$noGil';
      case PrefixType.mixer:
        final noMix = row['NoMixer'] ?? row['noMixer'] ?? '';
        final noSak = row['NoSak'] ?? row['noSak'] ?? '';
        return 'H.|Mixer_d|$noMix|$noSak';
      case PrefixType.bonggolan:
        final noBong = row['NoBonggolan'] ?? row['noBonggolan'] ?? '';
        return 'M.|Bonggolan|$noBong';
      case PrefixType.furnitureWip:
        final noFw = row['NoFurnitureWIP'] ??
            row['noFurnitureWIP'] ??
            row['noFurnitureWip'] ??
            '';
        return 'BB.|FurnitureWIP|$noFw';
      case PrefixType.barangJadi:
        final noBj =
            row['NoBJ'] ?? row['noBJ'] ?? row['noBj'] ?? '';
        return 'BA.|BarangJadi|$noBj';
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
    } else if (item is BbItem) {
      for (final existing in tempBbPartial) {
        if (existing.noBahanBaku == item.noBahanBaku &&
            existing.noPallet == item.noPallet &&
            existing.noSak == item.noSak) {
          return existing;
        }
      }
    } else if (item is GilinganItem) {
      for (final existing in tempGilinganPartial) {
        if (existing.noGilingan == item.noGilingan) {
          return existing;
        }
      }
    } else if (item is MixerItem) {
      for (final existing in tempMixerPartial) {
        if (existing.noMixer == item.noMixer && existing.noSak == item.noSak) {
          return existing;
        }
      }
    } else if (item is FurnitureWipItem) {
      for (final existing in tempFurnitureWipPartial) {
        if (existing.noFurnitureWIP == item.noFurnitureWIP) {
          return existing;
        }
      }
    } else if (item is BarangJadiItem) {
      for (final existing in tempBarangJadiPartial) {
        if (existing.noBJ == item.noBJ) {
          return existing;
        }
      }
    }
    return null;
  }

  double? _getWeightFromItem(dynamic item) {
    if (item is BrokerItem) return item.berat;
    if (item is BbItem) return item.berat;
    if (item is GilinganItem) return item.berat;
    if (item is MixerItem) return item.berat;
    if (item is BonggolanItem) return item.berat;
    if (item is FurnitureWipItem) return item.berat;
    if (item is BarangJadiItem) return item.berat;
    return null;
  }

  int? _getPcsFromItem(dynamic item) {
    if (item is FurnitureWipItem) return item.pcs;
    if (item is BarangJadiItem) return item.pcs;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Delete temp items (always maintain _tempKeys)
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

  void deleteTempBbItem(BbItem item) {
    tempBb.remove(item);
    tempBbPartial.remove(item);
    _tempKeys.remove(_keyFromBbItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempBbItem');
    notifyListeners();
  }

  void deleteTempWashingItem(WashingItem item) {
    tempWashing.remove(item);
    _tempKeys.remove(_keyFromWashingItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempWashingItem');
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

  void deleteTempGilinganItem(GilinganItem item) {
    tempGilingan.remove(item);
    tempGilinganPartial.remove(item);
    _tempKeys.remove(_keyFromGilinganItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempGilinganItem');
    notifyListeners();
  }

  void deleteTempMixerItem(MixerItem item) {
    tempMixer.remove(item);
    tempMixerPartial.remove(item);
    _tempKeys.remove(_keyFromMixerItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempMixerItem');
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

  void deleteTempFurnitureWipItem(FurnitureWipItem item) {
    tempFurnitureWip.remove(item);
    tempFurnitureWipPartial.remove(item);
    _tempKeys.remove(_keyFromFurnitureWipItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempFurnitureWipItem');
    notifyListeners();
  }

  void deleteTempBarangJadiItem(BarangJadiItem item) {
    tempBarangJadi.remove(item);
    tempBarangJadiPartial.remove(item);
    _tempKeys.remove(_keyFromBarangJadiItem(item));
    final code = _getItemLabelCode(item);
    if (code != null) _updateTempItemsByLabel(code);
    debugDumpTempLists(tag: 'after deleteTempBarangJadiItem');
    notifyListeners();
  }

  bool isInTempKeys(String key) => _tempKeys.contains(key);
  Set<String> getTempKeysForDebug() => Set.unmodifiable(_tempKeys);

  void clearAllTempItems() {
    tempBroker.clear();
    tempBrokerPartial.clear();
    tempBb.clear();
    tempBbPartial.clear();
    tempWashing.clear();
    tempCrusher.clear();
    tempGilingan.clear();
    tempGilinganPartial.clear();
    tempMixer.clear();
    tempMixerPartial.clear();
    tempBonggolan.clear();
    tempFurnitureWip.clear();
    tempFurnitureWipPartial.clear();
    tempBarangJadi.clear();
    tempBarangJadiPartial.clear();

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
    } else if (item is BbItem) {
      ok = tempBb.remove(item) || tempBbPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromBbItem(item));
    } else if (item is WashingItem) {
      ok = tempWashing.remove(item);
      if (ok) _tempKeys.remove(_keyFromWashingItem(item));
    } else if (item is CrusherItem) {
      ok = tempCrusher.remove(item);
      if (ok) _tempKeys.remove(_keyFromCrusherItem(item));
    } else if (item is GilinganItem) {
      ok = tempGilingan.remove(item) || tempGilinganPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromGilinganItem(item));
    } else if (item is MixerItem) {
      ok = tempMixer.remove(item) || tempMixerPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromMixerItem(item));
    } else if (item is BonggolanItem) {
      ok = tempBonggolan.remove(item);
      if (ok) _tempKeys.remove(_keyFromBonggolanItem(item));
    } else if (item is FurnitureWipItem) {
      ok = tempFurnitureWip.remove(item) ||
          tempFurnitureWipPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromFurnitureWipItem(item));
    } else if (item is BarangJadiItem) {
      ok = tempBarangJadi.remove(item) || tempBarangJadiPartial.remove(item);
      if (ok) _tempKeys.remove(_keyFromBarangJadiItem(item));
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

  // ===== Temp-partial numbering state (per kategori) =====
  final Map<PrefixType, int> _tempPartialSeq = {
    PrefixType.broker: 0,
    PrefixType.bb: 0,
    PrefixType.gilingan: 0,
    PrefixType.mixer: 0,
    PrefixType.reject: 0,
    PrefixType.furnitureWip: 0,  // ✅ TAMBAHKAN
    PrefixType.barangJadi: 0,     // ✅ TAMBAHKAN
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
      case PrefixType.bb:
        return 'P.XXXXXXXX ($numStr)';
      case PrefixType.gilingan:
        return 'Y.XXXXXXXX ($numStr)';
      case PrefixType.mixer:
        return 'T.XXXXXXXX ($numStr)';
      case PrefixType.bonggolan:
        return 'BK.XXXXXXXX ($numStr)';
      case PrefixType.furnitureWip:
        return 'BC.XXXXXXXX ($numStr)';  // ✅ GANTI dari W. ke BC.
      case PrefixType.barangJadi:
        return 'BL.XXXXXXXX ($numStr)';  // ✅ GANTI dari Z. ke BL.
      default:
        return '';
    }
  }

  /// create copy with temp-partial only if `isPartial==true` and category supports it
  dynamic _withTempPartialIfNeeded(
      dynamic item, PrefixType t, bool isPartial) {
    final supports = t == PrefixType.broker ||
        t == PrefixType.bb ||
        t == PrefixType.gilingan ||
        t == PrefixType.mixer ||
        t == PrefixType.furnitureWip ||
        t == PrefixType.barangJadi;
    if (!supports || !isPartial) return item;

    if (item is BrokerItem) {
      final already = (item.noBrokerPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noBrokerPartial: code);
      }
      return item;
    }

    if (item is BbItem) {
      final already = (item.noBBPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noBBPartial: code);
      }
      return item;
    }

    if (item is GilinganItem) {
      final already = (item.noGilinganPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noGilinganPartial: code);
      }
      return item;
    }

    if (item is MixerItem) {
      final already = (item.noMixerPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noMixerPartial: code);
      }
      return item;
    }

    if (item is FurnitureWipItem) {
      final already = (item.noFurnitureWIPPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noFurnitureWIPPartial: code);
      }
      return item;
    }

    if (item is BarangJadiItem) {
      final already = (item.noBJPartial ?? '').trim().isNotEmpty;
      if (!already) {
        final code = _formatTempPartial(t, _nextPartialSeq(t));
        return item.copyWith(noBJPartial: code);
      }
      return item;
    }

    return item;
  }

  int get totalTempCount =>
      tempBroker.length +
          tempBrokerPartial.length +
          tempBb.length +
          tempBbPartial.length +
          tempWashing.length +
          tempCrusher.length +
          tempGilingan.length +
          tempGilinganPartial.length +
          tempMixer.length +
          tempMixerPartial.length +
          tempBonggolan.length +
          tempFurnitureWip.length +
          tempFurnitureWipPartial.length +
          tempBarangJadi.length +
          tempBarangJadiPartial.length;

  // ---------------------------------------------------------------------------
  // Submit temp items to backend
  // ---------------------------------------------------------------------------
  bool isSubmitting = false;
  String? submitError;

  /// Build payload dari temp items sesuai format API
  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{};

    // Full items (non-partial)
    if (tempBroker.isNotEmpty) {
      payload['broker'] = tempBroker
          .map((e) => {
        'noBroker': e.noBroker,
        'noSak': e.noSak,
      })
          .toList();
    }

    if (tempBb.isNotEmpty) {
      payload['bb'] = tempBb
          .map((e) => {
        'noBahanBaku': e.noBahanBaku,
        'noPallet': e.noPallet,
        'noSak': e.noSak,
      })
          .toList();
    }

    if (tempWashing.isNotEmpty) {
      payload['washing'] = tempWashing
          .map((e) => {
        'noWashing': e.noWashing,
        'noSak': e.noSak,
      })
          .toList();
    }

    if (tempCrusher.isNotEmpty) {
      payload['crusher'] = tempCrusher
          .map((e) => {
        'noCrusher': e.noCrusher,
      })
          .toList();
    }

    if (tempGilingan.isNotEmpty) {
      payload['gilingan'] = tempGilingan
          .map((e) => {
        'noGilingan': e.noGilingan,
      })
          .toList();
    }

    if (tempMixer.isNotEmpty) {
      payload['mixer'] = tempMixer
          .map((e) => {
        'noMixer': e.noMixer,
        'noSak': e.noSak,
      })
          .toList();
    }

    if (tempBonggolan.isNotEmpty) {
      payload['bonggolan'] = tempBonggolan
          .map((e) => {
        'noBonggolan': e.noBonggolan,
      })
          .toList();
    }

    if (tempFurnitureWip.isNotEmpty) {
      payload['furnitureWip'] = tempFurnitureWip
          .map((e) => {
        'noFurnitureWip': e.noFurnitureWIP,
      })
          .toList();
    }

    if (tempBarangJadi.isNotEmpty) {
      payload['barangJadi'] = tempBarangJadi
          .map((e) => {
        'noBj': e.noBJ,
      })
          .toList();
    }

    // Partial items (tidak ada di broker production, skip brokerPartialNew)
    // Untuk Bongkar Susun, semua partial langsung disubmit bersama full items
    // Backend tidak membedakan partial baru vs existing

    return payload;
  }

  /// Submit all temp items to backend
  Future<bool> submitTempItems(String noBongkarSusun) async {
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

      _d('Submitting temp items to $noBongkarSusun');
      _d('Payload: ${json.encode(payload)}');

      final response = await repository.submitInputs(
        noBongkarSusun,
        payload,
      );

      _d('Submit response: ${json.encode(response)}');

      // Parse response
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

      // Success
      _d('Submit successful!');

      if (data != null) {
        _d('Response data: ${json.encode(data)}');
      }

      // Clear all temp items
      clearAllTempItems();

      // Clear lookup cache
      clearLookupCache();

      // Invalidate cache untuk noBongkarSusun ini
      clearInputsCache(noBongkarSusun);

      // Reload inputs
      await loadInputs(noBongkarSusun, force: true);

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

  /// Get summary of what will be submitted
  String getSubmitSummary() {
    if (totalTempCount == 0) return 'Tidak ada data';

    final parts = <String>[];

    if (tempBroker.isNotEmpty) {
      parts.add('${tempBroker.length} Broker');
    }
    if (tempBrokerPartial.isNotEmpty) {
      parts.add('${tempBrokerPartial.length} Broker Partial');
    }
    if (tempBb.isNotEmpty) {
      parts.add('${tempBb.length} Bahan Baku');
    }
    if (tempBbPartial.isNotEmpty) {
      parts.add('${tempBbPartial.length} BB Partial');
    }
    if (tempWashing.isNotEmpty) {
      parts.add('${tempWashing.length} Washing');
    }
    if (tempCrusher.isNotEmpty) {
      parts.add('${tempCrusher.length} Crusher');
    }
    if (tempGilingan.isNotEmpty) {
      parts.add('${tempGilingan.length} Gilingan');
    }
    if (tempGilinganPartial.isNotEmpty) {
      parts.add('${tempGilinganPartial.length} Gilingan Partial');
    }
    if (tempMixer.isNotEmpty) {
      parts.add('${tempMixer.length} Mixer');
    }
    if (tempMixerPartial.isNotEmpty) {
      parts.add('${tempMixerPartial.length} Mixer Partial');
    }
    if (tempBonggolan.isNotEmpty) {
      parts.add('${tempBonggolan.length} Bonggolan');
    }
    if (tempFurnitureWip.isNotEmpty) {
      parts.add('${tempFurnitureWip.length} Furniture WIP');
    }
    if (tempFurnitureWipPartial.isNotEmpty) {
      parts.add('${tempFurnitureWipPartial.length} Furniture WIP Partial');
    }
    if (tempBarangJadi.isNotEmpty) {
      parts.add('${tempBarangJadi.length} Barang Jadi');
    }
    if (tempBarangJadiPartial.isNotEmpty) {
      parts.add('${tempBarangJadiPartial.length} Barang Jadi Partial');
    }

    return 'Total $totalTempCount items:\n${parts.join(', ')}';
  }

  // ---------------------------------------------------------------------------
  // Delete inputs (DB + TEMP)
  // ---------------------------------------------------------------------------
  bool isDeleting = false;
  String? deleteError;
  Map<String, dynamic>? lastDeleteResult;

  /// Build payload untuk endpoint DELETE /api/bongkar-susun/:noBongkarSusun/inputs
  Map<String, dynamic> _buildDeletePayloadFromItems(List<dynamic> items) {
    final payload = <String, dynamic>{};

    void add(String key, Map<String, dynamic> row) {
      final list = (payload[key] ?? <Map<String, dynamic>>[])
      as List<Map<String, dynamic>>;
      list.add(row);
      payload[key] = list;
    }

    for (final it in items) {
      if (it is BrokerItem) {
        add('broker', {
          'noBroker': it.noBroker,
          'noSak': it.noSak,
        });
      } else if (it is BbItem) {
        add('bb', {
          'noBahanBaku': it.noBahanBaku,
          'noPallet': it.noPallet,
          'noSak': it.noSak,
        });
      } else if (it is WashingItem) {
        add('washing', {
          'noWashing': it.noWashing,
          'noSak': it.noSak,
        });
      } else if (it is CrusherItem) {
        add('crusher', {
          'noCrusher': it.noCrusher,
        });
      } else if (it is GilinganItem) {
        add('gilingan', {
          'noGilingan': it.noGilingan,
        });
      } else if (it is MixerItem) {
        add('mixer', {
          'noMixer': it.noMixer,
          'noSak': it.noSak,
        });
      } else if (it is BonggolanItem) {
        add('bonggolan', {
          'noBonggolan': it.noBonggolan,
        });
      } else if (it is FurnitureWipItem) {
        add('furnitureWip', {
          'noFurnitureWip': it.noFurnitureWIP,
        });
      } else if (it is BarangJadiItem) {
        add('barangJadi', {
          'noBj': it.noBJ,
        });
      }
    }
    return payload;
  }

  /// Hapus item (bisa campuran DB & TEMP)
  Future<bool> deleteItems(String noBongkarSusun, List<dynamic> items) async {
    if (items.isEmpty) {
      deleteError = 'Tidak ada data yang dipilih untuk dihapus';
      notifyListeners();
      return false;
    }

    // Pisahkan: mana yang temp, mana yang DB
    final List<dynamic> dbItems = [];

    for (final it in items) {
      final removedFromTemp = deleteIfTemp(it);
      if (!removedFromTemp) {
        dbItems.add(it);
      }
    }

    // Kalau semua ternyata temp → tidak perlu call API
    if (dbItems.isEmpty) {
      _d('deleteItems: hanya menghapus TEMP, tidak call API');
      notifyListeners();
      return true;
    }

    // Build payload dari DB items
    final payload = _buildDeletePayloadFromItems(dbItems);
    if (payload.isEmpty) {
      deleteError = 'Tidak ada data valid untuk dihapus (payload kosong)';
      notifyListeners();
      return false;
    }

    // Call API
    isDeleting = true;
    deleteError = null;
    notifyListeners();

    try {
      _d('deleteItems: calling deleteInputs for $noBongkarSusun');
      _d('Delete payload: ${json.encode(payload)}');

      final res = await repository.deleteInputs(noBongkarSusun, payload);
      lastDeleteResult = res;

      final success = res['success'] == true;
      final message = res['message'] as String? ?? '';

      _d('Delete response: ${json.encode(res)}');

      if (!success) {
        deleteError = message.isEmpty ? 'Gagal menghapus data' : message;
        return false;
      }

      // Berhasil: invalidasi & reload inputs
      clearInputsCache(noBongkarSusun);
      await loadInputs(noBongkarSusun, force: true);

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