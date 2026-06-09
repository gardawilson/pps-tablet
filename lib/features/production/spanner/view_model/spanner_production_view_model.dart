// lib/features/shared/spanner_production/view_model/spanner_production_view_model.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/spanner_production_model.dart';
import '../repository/spanner_production_repository.dart';

class SpannerProductionViewModel extends ChangeNotifier {
  final SpannerProductionRepository repository;

  // ✅ Constructor optional repository (samakan pola keyfitting/hotstamp)
  SpannerProductionViewModel({
    SpannerProductionRepository? repository,
  }) : repository = repository ?? SpannerProductionRepository() {
    debugPrint(
        '🟢 [SPANNER_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<SpannerProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================
  late final PagingController<int, SpannerProduction> _pagingController;
  PagingController<int, SpannerProduction> get pagingController =>
      _pagingController;

  void _initializePagingController() {
    debugPrint(
        '🟢 [SPANNER_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, SpannerProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [SPANNER_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
            '🟢 [SPANNER_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [SPANNER_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoProduksi (backend support LIKE search juga)
  String? _noProduksi;

  String get search => _search;
  String? get noProduksi => _noProduksi;

  // ===== Helper lama =====
  void clear() {
    debugPrint('🧹 [SPANNER_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [SPANNER_VM] fetchByDate($date), VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [SPANNER_VM] fetchByDate success, items=${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [SPANNER_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [SPANNER_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [SPANNER_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [SPANNER_VM] exitByDateMode -> pagingController.refresh()');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<SpannerProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [SPANNER_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint(
          '📡 [SPANNER_VM] _fetchPaged: isByDateMode=true -> empty list, VM hash=$hashCode');
      return const <SpannerProduction>[];
    }

    final String? searchQuery = (_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
        '📡 [SPANNER_VM] _fetchPaged filters -> search="$searchQuery", pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
      );

      final items = res['items'] as List<SpannerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [SPANNER_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint(
            '📡 [SPANNER_VM] _fetchPaged: pageKey > totalPages -> empty list, VM hash=$hashCode');
        return const <SpannerProduction>[];
      }

      debugPrint(
          '📡 [SPANNER_VM] _fetchPaged returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [SPANNER_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [SPANNER_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [SPANNER_VM] applyFilters(search="$search", newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noProduksi = null;
    if (search != null) _search = search;

    debugPrint('🔍 [SPANNER_VM] applyFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint(
        '🔍 [SPANNER_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _noProduksi = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [SPANNER_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    debugPrint('🧹 [SPANNER_VM] clearFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [SPANNER_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [SPANNER_VM] Calling _pagingController.refresh()');
    _pagingController.refresh();
    debugPrint('🔄 [SPANNER_VM] _pagingController.refresh() completed');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [SPANNER_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [SPANNER_VM] debounce fired, applyFilters("$text")');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<SpannerProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required List<int> idOperators,
    required int outputJenisId,
    required int idRegu,
    required int shift,
    required String hourStart,
    required String hourEnd,
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperators: idOperators,
        outputJenisId: outputJenisId,
        idRegu: idRegu,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
      );

      debugPrint(
          '🆕 [SPANNER_VM] createProduksi success, noProduksi=${created.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint('🆕 [SPANNER_VM] create in BY_DATE mode -> fetchByDate');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [SPANNER_VM] create in PAGED mode -> refreshPaged');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [SPANNER_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [SPANNER_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<SpannerProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jamKerja,
    int? shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    debugPrint(
        '✏️ [SPANNER_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jamKerja=$jamKerja, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, hourMeter=$hourMeter), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noProduksi: noProduksi,
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        jamKerja: jamKerja,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        checkBy1: checkBy1,
        checkBy2: checkBy2,
        approveBy: approveBy,
        hourMeter: hourMeter,
      );

      debugPrint(
          '✏️ [SPANNER_VM] updateProduksi success, noProduksi=${updated.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint('✏️ [SPANNER_VM] update BY_DATE -> fetchByDate($tglProduksi)');
          await fetchByDate(tglProduksi);
        } else {
          debugPrint('✏️ [SPANNER_VM] update BY_DATE no date -> refreshPaged()');
          refreshPaged();
        }
      } else {
        debugPrint('✏️ [SPANNER_VM] update PAGED -> refreshPaged()');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [SPANNER_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [SPANNER_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [SPANNER_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [SPANNER_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      refreshPaged();
      return true;
    } catch (e, st) {
      debugPrint('❌ [SPANNER_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [SPANNER_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [SPANNER_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
