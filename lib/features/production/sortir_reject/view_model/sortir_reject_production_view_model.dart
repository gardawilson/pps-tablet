import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/utils/date_formatter.dart';
import '../model/sortir_reject_production_model.dart';
import '../repository/sortir_reject_production_repository.dart';

class SortirRejectProductionViewModel extends ChangeNotifier {
  final SortirRejectProductionRepository repository;

  /// ✅ Constructor optional repository (same pattern as packing/spanner)
  SortirRejectProductionViewModel({
    SortirRejectProductionRepository? repository,
  }) : repository = repository ?? SortirRejectProductionRepository() {
    debugPrint(
        '🟢 [SORTIR_REJECT_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (optional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<SortirRejectProduction> items = [];
  bool isLoading = false;
  String error = '';

  /// last date for by-date mode
  DateTime? currentDate;

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================
  late final PagingController<int, SortirRejectProduction> _pagingController;
  PagingController<int, SortirRejectProduction> get pagingController =>
      _pagingController;

  void _initializePagingController() {
    debugPrint(
        '🟢 [SORTIR_REJECT_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, SortirRejectProduction>(
      getNextPageKey: (state) {
        debugPrint(
            '🟢 [SORTIR_REJECT_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
            '🟢 [SORTIR_REJECT_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [SORTIR_REJECT_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // =========================
  // Filters (paged mode)
  // =========================
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoBJSortir (backend supports LIKE search too)
  String? _noBJSortir;

  /// Optional date range (paged mode) -> controller supports dateFrom/dateTo
  DateTime? _dateFrom;
  DateTime? _dateTo;

  String get search => _search;
  String? get noBJSortir => _noBJSortir;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // =========================
  // BY DATE
  // =========================
  /// Load BJSortirReject_h untuk tanggal tertentu
  /// Backend: GET /api/production/sortir-reject/:date (YYYY-MM-DD)
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [SORTIR_REJECT_VM] fetchByDate($date), VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    currentDate = date;
    notifyListeners();

    try {
      items = await repository.fetchByDate(date);
      debugPrint(
          '📅 [SORTIR_REJECT_VM] fetchByDate success, items=${items.length}, VM hash=$hashCode');
    } catch (e, st) {
      debugPrint(
          '❌ [SORTIR_REJECT_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [SORTIR_REJECT_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Opsional: reload data untuk tanggal terakhir (by-date mode)
  Future<void> reload() async {
    if (currentDate == null) return;
    await fetchByDate(currentDate!);
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint(
        '🔁 [SORTIR_REJECT_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      currentDate = null;

      debugPrint(
          '🔁 [SORTIR_REJECT_VM] exitByDateMode -> pagingController.refresh()');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // =========================
  // FETCH per page (PagingController v5)
  // =========================
  Future<List<SortirRejectProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [SORTIR_REJECT_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint(
          '📡 [SORTIR_REJECT_VM] _fetchPaged: isByDateMode=true -> empty list, VM hash=$hashCode');
      return const <SortirRejectProduction>[];
    }

    final String? searchQuery = (_noBJSortir?.trim().isNotEmpty ?? false)
        ? _noBJSortir!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    final String? df = _dateFrom == null ? null : toDbDateString(_dateFrom!);
    final String? dt = _dateTo == null ? null : toDbDateString(_dateTo!);

    debugPrint(
        '📡 [SORTIR_REJECT_VM] _fetchPaged filters -> search="$searchQuery", dateFrom=$df, dateTo=$dt, pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
        dateFrom: df,
        dateTo: dt,
      );

      final pageItems = res['items'] as List<SortirRejectProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [SORTIR_REJECT_VM] _fetchPaged result: items.length=${pageItems.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint(
            '📡 [SORTIR_REJECT_VM] _fetchPaged: pageKey > totalPages -> empty list, VM hash=$hashCode');
        return const <SortirRejectProduction>[];
      }

      return pageItems;
    } catch (e, st) {
      debugPrint('❌ [SORTIR_REJECT_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [SORTIR_REJECT_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // =========================
  // Filter helpers (paged mode)
  // =========================
  void applyFilters({
    String? search,
    int? newPageSize,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    debugPrint(
        '🔍 [SORTIR_REJECT_VM] applyFilters(search="$search", newPageSize=$newPageSize, dateFrom=$dateFrom, dateTo=$dateTo), VM hash=$hashCode');

    _isByDateMode = false;
    currentDate = null;

    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    // update date range if provided (caller can pass null to clear)
    if (dateFrom != null || dateTo != null) {
      _dateFrom = dateFrom;
      _dateTo = dateTo;
    }

    _noBJSortir = null;
    if (search != null) _search = search;

    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoBJSortirContains(String text) {
    debugPrint(
        '🔍 [SORTIR_REJECT_VM] searchNoBJSortirContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _noBJSortir = text;
    _search = text;

    _pagingController.refresh();
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    debugPrint(
        '📆 [SORTIR_REJECT_VM] setDateRange(from=$from, to=$to), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _dateFrom = from;
    _dateTo = to;

    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [SORTIR_REJECT_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _search = '';
    _noBJSortir = null;
    _dateFrom = null;
    _dateTo = null;

    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [SORTIR_REJECT_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;
    _pagingController.refresh();
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [SORTIR_REJECT_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [SORTIR_REJECT_VM] debounce fired, applyFilters("$text")');
      applyFilters(search: text);
    });
  }

  // =========================
  // CREATE / UPDATE / DELETE
  // =========================
  Future<SortirRejectProduction?> createSortirReject({
    required DateTime tglBJSortir,
    required int idWarehouse,
    int? idUsername,
  }) async {
    debugPrint(
        '🆕 [SORTIR_REJECT_VM] createSortirReject(tgl=$tglBJSortir, idWarehouse=$idWarehouse, idUsername=$idUsername), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createSortirReject(
        tglBJSortir: tglBJSortir,
        idWarehouse: idWarehouse,
        idUsername: idUsername,
      );

      debugPrint(
          '🆕 [SORTIR_REJECT_VM] createSortirReject success, noBJSortir=${created.noBJSortir}, VM hash=$hashCode');

      // 🔄 auto refresh after create
      if (_isByDateMode) {
        await fetchByDate(tglBJSortir);
      } else {
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint(
          '❌ [SORTIR_REJECT_VM] createSortirReject error: $e, VM hash=$hashCode');
      debugPrint(
          '❌ [SORTIR_REJECT_VM] createSortirReject stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<SortirRejectProduction?> updateSortirReject({
    required String noBJSortir,
    DateTime? tglBJSortir,
    int? idWarehouse,
    int? idUsername,
  }) async {
    debugPrint(
        '✏️ [SORTIR_REJECT_VM] updateSortirReject(noBJSortir=$noBJSortir, tgl=$tglBJSortir, idWarehouse=$idWarehouse, idUsername=$idUsername), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateSortirReject(
        noBJSortir: noBJSortir,
        tglBJSortir: tglBJSortir,
        idWarehouse: idWarehouse,
        idUsername: idUsername,
      );

      debugPrint(
          '✏️ [SORTIR_REJECT_VM] updateSortirReject success, noBJSortir=${updated.noBJSortir}, VM hash=$hashCode');

      // 🔄 auto refresh after update
      if (_isByDateMode) {
        if (tglBJSortir != null) {
          await fetchByDate(tglBJSortir);
        } else if (currentDate != null) {
          await fetchByDate(currentDate!);
        } else {
          refreshPaged();
        }
      } else {
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint(
          '❌ [SORTIR_REJECT_VM] updateSortirReject error: $e, VM hash=$hashCode');
      debugPrint(
          '❌ [SORTIR_REJECT_VM] updateSortirReject stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSortirReject(String noBJSortir) async {
    debugPrint(
        '🗑 [SORTIR_REJECT_VM] deleteSortirReject(noBJSortir=$noBJSortir), VM hash=$hashCode');

    try {
      saveError = null;
      notifyListeners();

      await repository.deleteSortirReject(noBJSortir);

      // 🔄 auto refresh after delete
      if (_isByDateMode && currentDate != null) {
        await fetchByDate(currentDate!);
      } else {
        refreshPaged();
      }

      return true;
    } catch (e, st) {
      debugPrint(
          '❌ [SORTIR_REJECT_VM] deleteSortirReject error: $e, VM hash=$hashCode');
      debugPrint(
          '❌ [SORTIR_REJECT_VM] deleteSortirReject stack: $st');

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

  // =========================
  // Legacy helpers (keep)
  // =========================
  void clear() {
    items = [];
    error = '';
    isLoading = false;
    currentDate = null;
    _isByDateMode = false;

    // clear paged filters too
    _search = '';
    _noBJSortir = null;
    _dateFrom = null;
    _dateTo = null;

    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🔴 [SORTIR_REJECT_VM] dispose() called, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
