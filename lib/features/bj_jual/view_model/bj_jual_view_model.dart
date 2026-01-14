// lib/features/shared/bj_jual/view_model/bj_jual_view_model.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/utils/date_formatter.dart';
import '../model/bj_jual_model.dart';
import '../repository/bj_jual_repository.dart';

class BJJualViewModel extends ChangeNotifier {
  final BJJualRepository repository;

  BJJualViewModel({
    BJJualRepository? repository,
  }) : repository = repository ?? BJJualRepository() {
    debugPrint(
      '🟢 [BJ_JUAL_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode',
    );
    _initializePagingController();
  }

  // =========================
  // STATE
  // =========================
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // PAGED (TABLE)
  // =========================
  late final PagingController<int, BJJual> _pagingController;
  PagingController<int, BJJual> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint(
      '🟢 [BJ_JUAL_VM] _initializePagingController: creating controller, VM hash=$hashCode',
    );

    _pagingController = PagingController<int, BJJual>(
      getNextPageKey: (state) {
        debugPrint('🟢 [BJ_JUAL_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint(
          '🟢 [BJ_JUAL_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode',
        );
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [BJ_JUAL_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // =========================
  // FILTERS
  // =========================
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoBJJual (backend supports LIKE search too)
  String? _noBJJual;

  /// optional date range filter
  DateTime? _dateFrom;
  DateTime? _dateTo;

  String get search => _search;
  String? get noBJJual => _noBJJual;

  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // ===== Helper =====
  void clear() {
    debugPrint('🧹 [BJ_JUAL_VM] clear() called, VM hash=$hashCode');
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ====== FETCH per page (PagingController v5) ======
  Future<List<BJJual>> _fetchPaged(int pageKey) async {
    debugPrint('📡 [BJ_JUAL_VM] _fetchPaged(pageKey=$pageKey), VM hash=$hashCode');

    final String? searchQuery = (_noBJJual?.trim().isNotEmpty ?? false)
        ? _noBJJual!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
      '📡 [BJ_JUAL_VM] _fetchPaged filters -> search="$searchQuery", '
          'dateFrom=$_dateFrom, dateTo=$_dateTo, pageSize=$pageSize, VM hash=$hashCode',
    );

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
        // repo kamu sudah terima DateTime? via fetchAllList,
        // tapi di fetchAll kita pakai String dateFrom/dateTo.
        dateFrom: _dateFrom == null ? null : _toDbDateString(_dateFrom!),
        dateTo: _dateTo == null ? null : _toDbDateString(_dateTo!),
      );

      final items = res['items'] as List<BJJual>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
        '📡 [BJ_JUAL_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode',
      );

      if (pageKey > totalPages) {
        debugPrint(
          '📡 [BJ_JUAL_VM] _fetchPaged: pageKey > totalPages -> empty list, VM hash=$hashCode',
        );
        return const <BJJual>[];
      }

      debugPrint('📡 [BJ_JUAL_VM] _fetchPaged returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [BJ_JUAL_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [BJ_JUAL_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // =========================
  // FILTER HELPERS
  // =========================
  void applyFilters({
    String? search,
    int? newPageSize,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    debugPrint(
      '🔍 [BJ_JUAL_VM] applyFilters(search="$search", newPageSize=$newPageSize, dateFrom=$dateFrom, dateTo=$dateTo), VM hash=$hashCode',
    );

    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noBJJual = null;
    if (search != null) _search = search;

    // date range
    _dateFrom = dateFrom;
    _dateTo = dateTo;

    debugPrint('🔍 [BJ_JUAL_VM] applyFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoBJJualContains(String text) {
    debugPrint('🔍 [BJ_JUAL_VM] searchNoBJJualContains("$text"), VM hash=$hashCode');
    _noBJJual = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void setDateRange({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    debugPrint(
      '📅 [BJ_JUAL_VM] setDateRange(dateFrom=$dateFrom, dateTo=$dateTo), VM hash=$hashCode',
    );
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [BJ_JUAL_VM] clearFilters(), VM hash=$hashCode');
    _search = '';
    _noBJJual = null;
    _dateFrom = null;
    _dateTo = null;
    debugPrint('🧹 [BJ_JUAL_VM] clearFilters -> pagingController.refresh()');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [BJ_JUAL_VM] refreshPaged() called, VM hash=$hashCode');
    debugPrint('🔄 [BJ_JUAL_VM] Calling _pagingController.refresh()');
    _pagingController.refresh();
    debugPrint('🔄 [BJ_JUAL_VM] _pagingController.refresh() completed');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
      '⌛ [BJ_JUAL_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode',
    );
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [BJ_JUAL_VM] debounce fired, applyFilters("$text")');
      applyFilters(search: text, dateFrom: _dateFrom, dateTo: _dateTo);
    });
  }

  // =========================
  // CREATE
  // =========================
  Future<BJJual?> createBJJual({
    required DateTime tanggal,
    required int idPembeli,
    String? remark,
  }) async {
    debugPrint(
      '🆕 [BJ_JUAL_VM] createBJJual(tanggal=$tanggal, idPembeli=$idPembeli, remark=$remark), VM hash=$hashCode',
    );

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createBJJual(
        tanggal: tanggal,
        idPembeli: idPembeli,
        remark: remark,
      );

      debugPrint(
        '🆕 [BJ_JUAL_VM] createBJJual success, noBJJual=${created.noBJJual}, VM hash=$hashCode',
      );

      // refresh list
      refreshPaged();

      return created;
    } catch (e, st) {
      debugPrint('❌ [BJ_JUAL_VM] createBJJual error: $e, VM hash=$hashCode');
      debugPrint('❌ [BJ_JUAL_VM] createBJJual stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // =========================
  // UPDATE
  // =========================
  Future<BJJual?> updateBJJual({
    required String noBJJual,
    DateTime? tanggal,
    int? idPembeli,
    String? remark,
  }) async {
    debugPrint(
      '✏️ [BJ_JUAL_VM] updateBJJual(noBJJual=$noBJJual, tanggal=$tanggal, idPembeli=$idPembeli, remark=$remark), VM hash=$hashCode',
    );

    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateBJJual(
        noBJJual: noBJJual,
        tanggal: tanggal,
        idPembeli: idPembeli,
        remark: remark,
      );

      debugPrint(
        '✏️ [BJ_JUAL_VM] updateBJJual success, noBJJual=${updated.noBJJual}, VM hash=$hashCode',
      );

      refreshPaged();
      return updated;
    } catch (e, st) {
      debugPrint('❌ [BJ_JUAL_VM] updateBJJual error: $e, VM hash=$hashCode');
      debugPrint('❌ [BJ_JUAL_VM] updateBJJual stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<bool> deleteBJJual(String noBJJual) async {
    debugPrint('🗑 [BJ_JUAL_VM] deleteBJJual(noBJJual=$noBJJual), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteBJJual(noBJJual);
      debugPrint('🗑 [BJ_JUAL_VM] deleteBJJual success, VM hash=$hashCode');

      refreshPaged();
      return true;
    } catch (e, st) {
      debugPrint('❌ [BJ_JUAL_VM] deleteBJJual error: $e, VM hash=$hashCode');
      debugPrint('❌ [BJ_JUAL_VM] deleteBJJual stack: $st');

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
  // UTIL
  // =========================
  String _toDbDateString(DateTime d) {
    // kamu sudah punya toDbDateString di core/utils/date_formatter.dart,
    // tapi biar VM ini mandiri, aku wrap juga.
    return toDbDateString(d);
  }

  @override
  void dispose() {
    debugPrint('🔴 [BJ_JUAL_VM] dispose() called, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
