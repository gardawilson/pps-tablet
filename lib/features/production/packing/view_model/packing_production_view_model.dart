// lib/features/shared/packing_production/view_model/packing_production_view_model.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/packing_production_model.dart';
import '../repository/packing_production_repository.dart';

class PackingProductionViewModel extends ChangeNotifier {
  final PackingProductionRepository repository;

  // ✅ Constructor optional repository (same pattern as spanner)
  PackingProductionViewModel({
    PackingProductionRepository? repository,
  }) : repository = repository ?? PackingProductionRepository() {
    debugPrint(
        '🟢 [PACKING_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (optional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<PackingProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================
  late final PagingController<int, PackingProduction> _pagingController;
  PagingController<int, PackingProduction> get pagingController =>
      _pagingController;

  void _initializePagingController() {
    debugPrint(
        '🟢 [PACKING_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, PackingProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [PACKING_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
            '🟢 [PACKING_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [PACKING_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoPacking (backend supports LIKE search too)
  String? _noPacking;

  String get search => _search;
  String? get noPacking => _noPacking;

  // ===== Helper =====
  void clear() {
    debugPrint('🧹 [PACKING_VM] clear() called, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [PACKING_VM] fetchByDate($date), VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [PACKING_VM] fetchByDate success, items=${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [PACKING_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [PACKING_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [PACKING_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [PACKING_VM] exitByDateMode -> pagingController.refresh()');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per page (PagingController v5) ======
  Future<List<PackingProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [PACKING_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint(
          '📡 [PACKING_VM] _fetchPaged: isByDateMode=true -> empty list, VM hash=$hashCode');
      return const <PackingProduction>[];
    }

    final String? searchQuery = (_noPacking?.trim().isNotEmpty ?? false)
        ? _noPacking!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
        '📡 [PACKING_VM] _fetchPaged filters -> search="$searchQuery", pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
      );

      final items = res['items'] as List<PackingProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [PACKING_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint(
            '📡 [PACKING_VM] _fetchPaged: pageKey > totalPages -> empty list, VM hash=$hashCode');
        return const <PackingProduction>[];
      }

      debugPrint(
          '📡 [PACKING_VM] _fetchPaged returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [PACKING_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [PACKING_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (paged mode) ======
  void applyFilters({
    String? search,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [PACKING_VM] applyFilters(search="$search", newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noPacking = null;
    if (search != null) _search = search;

    debugPrint('🔍 [PACKING_VM] applyFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoPackingContains(String text) {
    debugPrint(
        '🔍 [PACKING_VM] searchNoPackingContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _noPacking = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [PACKING_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noPacking = null;
    debugPrint('🧹 [PACKING_VM] clearFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [PACKING_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [PACKING_VM] Calling _pagingController.refresh()');
    _pagingController.refresh();
    debugPrint('🔄 [PACKING_VM] _pagingController.refresh() completed');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [PACKING_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [PACKING_VM] debounce fired, applyFilters("$text")');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<PackingProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jamKerja, // int or String
    required int shift,
    required String hourStart,
    required String hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    debugPrint(
        '🆕 [PACKING_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jamKerja=$jamKerja, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, hourMeter=$hourMeter), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
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
          '🆕 [PACKING_VM] createProduksi success, noPacking=${created.noPacking}, VM hash=$hashCode');

      // 🔄 auto refresh after create
      if (_isByDateMode) {
        debugPrint('🆕 [PACKING_VM] create in BY_DATE mode -> fetchByDate');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [PACKING_VM] create in PAGED mode -> refreshPaged');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [PACKING_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [PACKING_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<PackingProduction?> updateProduksi({
    required String noPacking,
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
        '✏️ [PACKING_VM] updateProduksi(noPacking=$noPacking, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jamKerja=$jamKerja, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, hourMeter=$hourMeter), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noPacking: noPacking,
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
          '✏️ [PACKING_VM] updateProduksi success, noPacking=${updated.noPacking}, VM hash=$hashCode');

      // 🔄 auto refresh after update
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint('✏️ [PACKING_VM] update BY_DATE -> fetchByDate($tglProduksi)');
          await fetchByDate(tglProduksi);
        } else {
          debugPrint('✏️ [PACKING_VM] update BY_DATE no date -> refreshPaged()');
          refreshPaged();
        }
      } else {
        debugPrint('✏️ [PACKING_VM] update PAGED -> refreshPaged()');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [PACKING_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [PACKING_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noPacking) async {
    debugPrint('🗑 [PACKING_VM] deleteProduksi(noPacking=$noPacking), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noPacking);
      debugPrint('🗑 [PACKING_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 auto refresh after delete
      refreshPaged();
      return true;
    } catch (e, st) {
      debugPrint('❌ [PACKING_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [PACKING_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [PACKING_VM] dispose() called, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
