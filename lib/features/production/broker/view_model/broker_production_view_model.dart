// lib/features/broker/view_model/broker_production_view_model.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/broker_production_repository.dart';
import '../model/broker_production_model.dart';
import '../model/broker_inputs_model.dart';

class BrokerProductionViewModel extends ChangeNotifier {
  final BrokerProductionRepository repository;

  // ✅ Constructor dengan optional repository parameter
  BrokerProductionViewModel({
    BrokerProductionRepository? repository,
  }) : repository = repository ?? BrokerProductionRepository() {
    debugPrint('🟢 [BROKER_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (TETAP)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<BrokerProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE STATE ======
  bool isSaving = false;
  String? saveError;

  // To prevent duplicate per-row inputs fetch
  final Map<String, Future<BrokerInputs>> _inflight = {};

  // =========================
  // MODE PAGED
  // =========================
  late final PagingController<int, BrokerProduction> _pagingController;
  PagingController<int, BrokerProduction> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint('🟢 [BROKER_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, BrokerProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [BROKER_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint('🟢 [BROKER_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [BROKER_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search (backend searches **NoProduksi LIKE**)
  String _search = '';

  /// "Exact" NoProduksi (convenience). Backend still does LIKE; we keep this
  /// so UI can choose an exact flow (e.g., from a suggestion list).
  String? _noProduksi;
  bool _exactNoProduksi = false;

  int? _shift;
  DateTime? _date; // legacy single-day filter (mapped to dateFrom/dateTo in repo)

  String get search => _search;
  String? get noProduksi => _noProduksi;
  bool get exactNoProduksi => _exactNoProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ======================================================
  // INPUTS PER-ROW (cache, loading & error per NoProduksi)
  // ======================================================
  final Map<String, BrokerInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noProduksi) => _inputsLoading[noProduksi] == true;
  String? inputsError(String noProduksi) => _inputsError[noProduksi];
  BrokerInputs? inputsOf(String noProduksi) => _inputsCache[noProduksi];
  int inputsCount(String noProduksi, String key) =>
      _inputsCache[noProduksi]?.summary[key] ?? 0;

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

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [BROKER_VM] fetchByDate($date) dipanggil, VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint('📅 [BROKER_VM] fetchByDate success, items length = ${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [BROKER_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [BROKER_VM] fetchByDate stack: $st');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [BROKER_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [BROKER_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<BrokerProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [BROKER_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [BROKER_VM] _fetchPaged: isByDateMode=true, return empty, VM hash=$hashCode');
      return const <BrokerProduction>[];
    }

    // Decide what to send to repository:
    final String? searchContains = _exactNoProduksi
        ? null
        : ((_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null));

    final String? noProduksiExact = _exactNoProduksi
        ? (_noProduksi?.trim().isNotEmpty == true ? _noProduksi!.trim() : null)
        : null;

    debugPrint(
        '📡 [BROKER_VM] _fetchPaged filters -> searchContains="$searchContains", noProduksiExact="$noProduksiExact", shift=$_shift, date=$_date, pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchContains,
        noProduksi: noProduksiExact,
        exactNoProduksi: _exactNoProduksi,
        shift: _shift,
        date: _date,
      );

      final items = res['items'] as List<BrokerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [BROKER_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint('📡 [BROKER_VM] _fetchPaged: pageKey > totalPages, return empty, VM hash=$hashCode');
        return const <BrokerProduction>[];
      }

      debugPrint('📡 [BROKER_VM] _fetchPaged: returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [BROKER_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [BROKER_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======

  /// Pencarian generic (contains). Dipakai action bar search biasa.
  void applyFilters({
    String? search,
    int? shift,
    DateTime? date,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [BROKER_VM] applyFilters(search="$search", shift=$shift, date=$date, newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    // mode contains (reset exact)
    _exactNoProduksi = false;
    _noProduksi = null;
    if (search != null) _search = search;

    _shift = shift;
    _date = date;

    clearInputsCache();
    debugPrint('🔍 [BROKER_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoProduksi dengan contains (LIKE '%text%')
  void searchNoProduksiContains(String text) {
    debugPrint('🔍 [BROKER_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoProduksi = false;
    _noProduksi = text;
    // Optional: keep _search in sync for UIs that only know 'search'
    _search = text;
    clearInputsCache();
    _pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoProduksi exact (persis sama).
  void searchNoProduksiExact(String no) {
    debugPrint('🔍 [BROKER_VM] searchNoProduksiExact("$no"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoProduksi = true;
    _noProduksi = no;
    clearInputsCache();
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [BROKER_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    _exactNoProduksi = false;
    _shift = null;
    _date = null;

    clearInputsCache();
    debugPrint('🧹 [BROKER_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [BROKER_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    clearInputsCache();
    debugPrint('🔄 [BROKER_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint('🔄 [BROKER_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [BROKER_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [BROKER_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<BrokerProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jam, // int atau 'HH:mm-HH:mm'
    required int shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '🆕 [BROKER_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        jam: jam,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        checkBy1: checkBy1,
        checkBy2: checkBy2,
        approveBy: approveBy,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '🆕 [BROKER_VM] createProduksi success, noProduksi=${created?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint('🆕 [BROKER_VM] create in BY_DATE mode -> fetchByDate, VM hash=$hashCode');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [BROKER_VM] create in PAGED mode -> refreshPaged, VM hash=$hashCode');
        clearInputsCache();
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [BROKER_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [BROKER_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<BrokerProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jam, // int atau 'HH:mm-HH:mm'
    int? shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '✏️ [BROKER_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noProduksi: noProduksi,
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        jam: jam,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        checkBy1: checkBy1,
        checkBy2: checkBy2,
        approveBy: approveBy,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '✏️ [BROKER_VM] updateProduksi success, noProduksi=${updated?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint(
              '✏️ [BROKER_VM] update in BY_DATE mode, tglProduksi!=null -> fetchByDate($tglProduksi), VM hash=$hashCode');
          await fetchByDate(tglProduksi);
        } else if (_date != null) {
          debugPrint(
              '✏️ [BROKER_VM] update in BY_DATE mode, _date!=null -> fetchByDate($_date), VM hash=$hashCode');
          await fetchByDate(_date!);
        } else {
          debugPrint(
              '✏️ [BROKER_VM] update in BY_DATE mode, no date info -> refreshPaged(), VM hash=$hashCode');
          clearInputsCache(noProduksi);
          refreshPaged();
        }
      } else {
        debugPrint('✏️ [BROKER_VM] update in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        clearInputsCache(noProduksi);
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [BROKER_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [BROKER_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [BROKER_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [BROKER_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      if (isByDateMode) {
        if (date != null) {
          debugPrint(
              '🗑 [BROKER_VM] delete in BY_DATE mode -> fetchByDate($date), VM hash=$hashCode');
          await fetchByDate(date!);
        }
      } else {
        debugPrint('🗑 [BROKER_VM] delete in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        clearInputsCache(noProduksi);
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [BROKER_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [BROKER_VM] deleteProduksi stack: $st');

      String msg = e.toString().replaceFirst('Exception: ', '').trim();

      if (msg.startsWith('{') && msg.endsWith('}')) {
        try {
          final decoded = jsonDecode(msg);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
      }

      saveError = msg;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    debugPrint('🔴 [BROKER_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}