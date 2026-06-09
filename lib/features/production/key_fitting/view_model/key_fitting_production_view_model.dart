// lib/features/shared/key_fitting_production/view_model/packing_production_view_model.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/key_fitting_production_model.dart';
import '../repository/key_fitting_production_repository.dart';

class KeyFittingProductionViewModel extends ChangeNotifier {
  final KeyFittingProductionRepository repository;

  // ✅ Constructor dengan optional repository parameter (samakan pola hotstamp)
  KeyFittingProductionViewModel({
    KeyFittingProductionRepository? repository,
  }) : repository = repository ?? KeyFittingProductionRepository() {
    debugPrint(
        '🟢 [KEYFITTING_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<KeyFittingProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================
  late final PagingController<int, KeyFittingProduction> _pagingController;
  PagingController<int, KeyFittingProduction> get pagingController =>
      _pagingController;

  void _initializePagingController() {
    debugPrint(
        '🟢 [KEYFITTING_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, KeyFittingProduction>(
      getNextPageKey: (state) {
        debugPrint(
            '🟢 [KEYFITTING_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
            '🟢 [KEYFITTING_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [KEYFITTING_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
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
    debugPrint('🧹 [KEYFITTING_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [KEYFITTING_VM] fetchByDate($date), VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [KEYFITTING_VM] fetchByDate success, items=${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [KEYFITTING_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [KEYFITTING_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint(
        '🔁 [KEYFITTING_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint(
          '🔁 [KEYFITTING_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<KeyFittingProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [KEYFITTING_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint(
          '📡 [KEYFITTING_VM] _fetchPaged: isByDateMode=true -> empty list, VM hash=$hashCode');
      return const <KeyFittingProduction>[];
    }

    final String? searchQuery = (_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
        '📡 [KEYFITTING_VM] _fetchPaged filters -> search="$searchQuery", pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
      );

      final items = res['items'] as List<KeyFittingProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [KEYFITTING_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint(
            '📡 [KEYFITTING_VM] _fetchPaged: pageKey > totalPages -> empty list, VM hash=$hashCode');
        return const <KeyFittingProduction>[];
      }

      debugPrint(
          '📡 [KEYFITTING_VM] _fetchPaged returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [KEYFITTING_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [KEYFITTING_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [KEYFITTING_VM] applyFilters(search="$search", newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noProduksi = null;
    if (search != null) _search = search;

    debugPrint(
        '🔍 [KEYFITTING_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint(
        '🔍 [KEYFITTING_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _noProduksi = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [KEYFITTING_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    debugPrint(
        '🧹 [KEYFITTING_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [KEYFITTING_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint(
        '🔄 [KEYFITTING_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint(
        '🔄 [KEYFITTING_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [KEYFITTING_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint(
          '⌛ [KEYFITTING_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<KeyFittingProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required List<int> idOperators,
    required int outputJenisId,
    required int shift,
    int? idRegu,
    int? jamKerja,
    int? hourMeter,
    String? hourStart,
    String? hourEnd,
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
        shift: shift,
        idRegu: idRegu,
        jamKerja: jamKerja,
        hourMeter: hourMeter,
        hourStart: hourStart,
        hourEnd: hourEnd,
      );

      if (_isByDateMode) {
        await fetchByDate(tglProduksi);
      } else {
        refreshPaged();
      }

      return created;
    } catch (e) {
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<KeyFittingProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    List<int>? idOperators,
    int? outputJenisId,
    int? idRegu,
    int? shift,
    int? jamKerja,
    int? hourMeter,
    String? hourStart,
    String? hourEnd,
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noProduksi: noProduksi,
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperators: idOperators,
        outputJenisId: outputJenisId,
        idRegu: idRegu,
        shift: shift,
        jamKerja: jamKerja,
        hourMeter: hourMeter,
        hourStart: hourStart,
        hourEnd: hourEnd,
      );

      if (_isByDateMode && tglProduksi != null) {
        await fetchByDate(tglProduksi);
      } else {
        refreshPaged();
      }

      return updated;
    } catch (e) {
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint(
        '🗑 [KEYFITTING_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [KEYFITTING_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      refreshPaged();
      return true;
    } catch (e, st) {
      debugPrint('❌ [KEYFITTING_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [KEYFITTING_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [KEYFITTING_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
