// lib/features/shared/return_production/view_model/return_production_view_model.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/utils/date_formatter.dart';
import '../model/return_production_model.dart';
import '../repository/return_production_repository.dart';

class ReturnProductionViewModel extends ChangeNotifier {
  final ReturnProductionRepository repository;

  /// ✅ Constructor optional repository (same pattern as sortir-reject/packing/spanner)
  ReturnProductionViewModel({
    ReturnProductionRepository? repository,
  }) : repository = repository ?? ReturnProductionRepository() {
    debugPrint(
        '🟢 [RETURN_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (optional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<ReturnProduction> items = [];
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
  late final PagingController<int, ReturnProduction> _pagingController;
  PagingController<int, ReturnProduction> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint(
        '🟢 [RETURN_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, ReturnProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [RETURN_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
            '🟢 [RETURN_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [RETURN_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // =========================
  // Filters (paged mode)
  // =========================
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoRetur (optional helper; backend uses search LIKE too)
  String? _noRetur;

  /// Optional date range (paged mode)
  DateTime? _dateFrom;
  DateTime? _dateTo;

  String get search => _search;
  String? get noRetur => _noRetur;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // =========================
  // BY DATE
  // =========================
  /// Load BJRetur_h untuk tanggal tertentu
  /// Backend: GET /api/production/return/:date (YYYY-MM-DD)
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [RETURN_VM] fetchByDate($date), VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    currentDate = date;
    notifyListeners();

    try {
      items = await repository.fetchByDate(date);
      debugPrint(
          '📅 [RETURN_VM] fetchByDate success, items=${items.length}, VM hash=$hashCode');
    } catch (e, st) {
      debugPrint('❌ [RETURN_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [RETURN_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (currentDate == null) return;
    await fetchByDate(currentDate!);
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [RETURN_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      currentDate = null;

      debugPrint('🔁 [RETURN_VM] exitByDateMode -> pagingController.refresh()');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // =========================
  // FETCH per page (PagingController v5)
  // =========================
  Future<List<ReturnProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [RETURN_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [RETURN_VM] _fetchPaged: isByDateMode=true -> empty list');
      return const <ReturnProduction>[];
    }

    final String? searchQuery = (_noRetur?.trim().isNotEmpty ?? false)
        ? _noRetur!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    final String? df = _dateFrom == null ? null : toDbDateString(_dateFrom!);
    final String? dt = _dateTo == null ? null : toDbDateString(_dateTo!);

    debugPrint(
        '📡 [RETURN_VM] _fetchPaged filters -> search="$searchQuery", dateFrom=$df, dateTo=$dt, pageSize=$pageSize');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
        dateFrom: df,
        dateTo: dt,
      );

      final pageItems = res['items'] as List<ReturnProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [RETURN_VM] _fetchPaged result: items.length=${pageItems.length}, totalPages=$totalPages, currentPage=$pageKey');

      if (pageKey > totalPages) return const <ReturnProduction>[];
      return pageItems;
    } catch (e, st) {
      debugPrint('❌ [RETURN_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [RETURN_VM] _fetchPaged stack: $st');
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
        '🔍 [RETURN_VM] applyFilters(search="$search", newPageSize=$newPageSize, dateFrom=$dateFrom, dateTo=$dateTo), VM hash=$hashCode');

    _isByDateMode = false;
    currentDate = null;

    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    if (dateFrom != null || dateTo != null) {
      _dateFrom = dateFrom;
      _dateTo = dateTo;
    }

    _noRetur = null;
    if (search != null) _search = search;

    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoReturContains(String text) {
    debugPrint('🔍 [RETURN_VM] searchNoReturContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _noRetur = text;
    _search = text;

    _pagingController.refresh();
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    debugPrint('📆 [RETURN_VM] setDateRange(from=$from, to=$to), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _dateFrom = from;
    _dateTo = to;

    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [RETURN_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    currentDate = null;

    _search = '';
    _noRetur = null;
    _dateFrom = null;
    _dateTo = null;

    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [RETURN_VM] refreshPaged() called, VM hash=$hashCode');
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
        '⌛ [RETURN_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [RETURN_VM] debounce fired, applyFilters("$text")');
      applyFilters(search: text);
    });
  }

  // =========================
  // CREATE / UPDATE / DELETE
  // =========================
  Future<ReturnProduction?> createReturn({
    required DateTime tanggal,
    required int idPembeli,
    String? invoice,
    String? noBJSortir,
  }) async {
    debugPrint(
        '🆕 [RETURN_VM] createReturn(tanggal=$tanggal, idPembeli=$idPembeli, invoice=$invoice, noBJSortir=$noBJSortir), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createReturn(
        tanggal: tanggal,
        idPembeli: idPembeli,
        invoice: invoice,
        noBJSortir: noBJSortir,
      );

      debugPrint(
          '🆕 [RETURN_VM] createReturn success, noRetur=${created.noRetur}, VM hash=$hashCode');

      // 🔄 auto refresh after create
      if (_isByDateMode) {
        await fetchByDate(tanggal);
      } else {
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [RETURN_VM] createReturn error: $e, VM hash=$hashCode');
      debugPrint('❌ [RETURN_VM] createReturn stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// ✅ header-only update (matches your fixed req body format)
  Future<ReturnProduction?> updateReturn({
    required String noRetur,
    DateTime? tanggal,
    String? invoice,
    int? idPembeli,
    String? noBJSortir,
  }) async {
    debugPrint(
        '✏️ [RETURN_VM] updateReturn(noRetur=$noRetur, tanggal=$tanggal, invoice=$invoice, idPembeli=$idPembeli, noBJSortir=$noBJSortir), VM hash=$hashCode');

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateReturn(
        noRetur: noRetur,
        tanggal: tanggal,
        invoice: invoice,
        idPembeli: idPembeli,
        noBJSortir: noBJSortir,
      );

      debugPrint(
          '✏️ [RETURN_VM] updateReturn success, noRetur=${updated.noRetur}, VM hash=$hashCode');

      // 🔄 auto refresh after update
      if (_isByDateMode) {
        if (tanggal != null) {
          await fetchByDate(tanggal);
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
      debugPrint('❌ [RETURN_VM] updateReturn error: $e, VM hash=$hashCode');
      debugPrint('❌ [RETURN_VM] updateReturn stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReturn(String noRetur) async {
    debugPrint('🗑 [RETURN_VM] deleteReturn(noRetur=$noRetur), VM hash=$hashCode');

    try {
      saveError = null;
      notifyListeners();

      await repository.deleteReturn(noRetur);

      // 🔄 auto refresh after delete
      if (_isByDateMode && currentDate != null) {
        await fetchByDate(currentDate!);
      } else {
        refreshPaged();
      }

      return true;
    } catch (e, st) {
      debugPrint('❌ [RETURN_VM] deleteReturn error: $e, VM hash=$hashCode');
      debugPrint('❌ [RETURN_VM] deleteReturn stack: $st');

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

    _search = '';
    _noRetur = null;
    _dateFrom = null;
    _dateTo = null;

    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🔴 [RETURN_VM] dispose() called, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
