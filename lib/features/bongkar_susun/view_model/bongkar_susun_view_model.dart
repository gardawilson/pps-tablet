// lib/features/shared/bongkar_susun/view_model/bongkar_susun_view_model.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/network/api_error.dart';
import '../repository/bongkar_susun_repository.dart';
import '../model/bongkar_susun_model.dart';

class BongkarSusunViewModel extends ChangeNotifier {
  final BongkarSusunRepository repository;

  // ✅ Repository di-inject via constructor
  BongkarSusunViewModel({
    BongkarSusunRepository? repository,  // ← Optional parameter
  }) : repository = repository ?? BongkarSusunRepository() {  // ← Default fallback
    debugPrint('🟢 [VM] ctor called, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<BongkarSusun> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE) - v5.1.1 API
  // =========================

  late final PagingController<int, BongkarSusun> _pagingController;
  PagingController<int, BongkarSusun> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint('🟢 [BONGKAR_SUSUN_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, BongkarSusun>(
      getNextPageKey: (state) {
        debugPrint('🟢 [BONGKAR_SUSUN_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint('🟢 [BONGKAR_SUSUN_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [BONGKAR_SUSUN_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;
  String _search = '';
  String? _noBongkarSusun;
  bool _exactNoBongkarSusun = false;
  DateTime? _date;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _idUsername;

  String get search => _search;
  String? get noBongkarSusun => _noBongkarSusun;
  bool get exactNoBongkarSusun => _exactNoBongkarSusun;
  DateTime? get date => _date;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  int? get idUsername => _idUsername;

  // ===== Helper lama kalau ada kode lain yang pakai =====
  void clear() {
    debugPrint('🧹 [BONGKAR_SUSUN_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [BONGKAR_SUSUN_VM] fetchByDate($date) dipanggil, VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [BONGKAR_SUSUN_VM] fetchByDate success, items length = ${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [BONGKAR_SUSUN_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [BONGKAR_SUSUN_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [BONGKAR_SUSUN_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [BONGKAR_SUSUN_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (v5.1.1 - returns Future<List<T>>) ======
  Future<List<BongkarSusun>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [BONGKAR_SUSUN_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [BONGKAR_SUSUN_VM] _fetchPaged: isByDateMode=true, return empty, VM hash=$hashCode');
      return [];
    }

    final String? searchContains = _exactNoBongkarSusun
        ? null
        : ((_noBongkarSusun?.trim().isNotEmpty ?? false)
        ? _noBongkarSusun!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null));

    final String? noBongkarSusunExact = _exactNoBongkarSusun
        ? (_noBongkarSusun?.trim().isNotEmpty == true
        ? _noBongkarSusun!.trim()
        : null)
        : null;

    debugPrint(
        '📡 [BONGKAR_SUSUN_VM] _fetchPaged filters -> searchContains="$searchContains", noBongkarSusunExact="$noBongkarSusunExact", date=$_date, dateFrom=$_dateFrom, dateTo=$_dateTo, idUsername=$_idUsername, pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchContains,
        noBongkarSusun: noBongkarSusunExact,
        exactNoBongkarSusun: _exactNoBongkarSusun,
        date: _date,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        idUsername: _idUsername,
      );

      final items = res['items'] as List<BongkarSusun>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [BONGKAR_SUSUN_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint('📡 [BONGKAR_SUSUN_VM] _fetchPaged: pageKey > totalPages, return empty, VM hash=$hashCode');
        return [];
      }

      debugPrint('📡 [BONGKAR_SUSUN_VM] _fetchPaged: returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [BONGKAR_SUSUN_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [BONGKAR_SUSUN_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    DateTime? date,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idUsername,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [BONGKAR_SUSUN_VM] applyFilters(search="$search", date=$date, dateFrom=$dateFrom, dateTo=$dateTo, idUsername=$idUsername, newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _exactNoBongkarSusun = false;
    _noBongkarSusun = null;
    if (search != null) _search = search;

    _date = date;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _idUsername = idUsername;

    debugPrint('🔍 [BONGKAR_SUSUN_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();

    notifyListeners();
  }

  void searchNoBongkarSusunContains(String text) {
    debugPrint('🔍 [BONGKAR_SUSUN_VM] searchNoBongkarSusunContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoBongkarSusun = false;
    _noBongkarSusun = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoBongkarSusunExact(String no) {
    debugPrint('🔍 [BONGKAR_SUSUN_VM] searchNoBongkarSusunExact("$no"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoBongkarSusun = true;
    _noBongkarSusun = no;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [BONGKAR_SUSUN_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noBongkarSusun = null;
    _exactNoBongkarSusun = false;
    _date = null;
    _dateFrom = null;
    _dateTo = null;
    _idUsername = null;
    debugPrint('🧹 [BONGKAR_SUSUN_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [BONGKAR_SUSUN_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [BONGKAR_SUSUN_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint('🔄 [BONGKAR_SUSUN_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [BONGKAR_SUSUN_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [BONGKAR_SUSUN_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ==============================
  // CREATE  (POST /api/bongkar-susun)
  // ==============================
  Future<BongkarSusun?> createBongkarSusun({
    required DateTime tanggal,
    String? note,
  }) async {
    debugPrint(
        '🆕 [BONGKAR_SUSUN_VM] createBongkarSusun(tanggal=$tanggal, note=$note), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createBongkarSusun(
        tanggal: tanggal,
        note: note,
      );

      debugPrint(
          '🆕 [BONGKAR_SUSUN_VM] createBongkarSusun success, noBongkarSusun=${created.noBongkarSusun}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint(
            '🆕 [BONGKAR_SUSUN_VM] create in BY_DATE mode -> fetchByDate($tanggal), VM hash=$hashCode');
        await fetchByDate(tanggal);
      } else {
        debugPrint(
            '🆕 [BONGKAR_SUSUN_VM] create in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [BONGKAR_SUSUN_VM] createBongkarSusun error: $e, VM hash=$hashCode');
      debugPrint('❌ [BONGKAR_SUSUN_VM] createBongkarSusun stack: $st');
      saveError = apiErrorMessage(e); // ✅ ini yang ditampilkan ke dialog
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ==============================
  // UPDATE (PUT /api/bongkar-susun/:noBongkarSusun)
  // ==============================
  Future<BongkarSusun?> updateBongkarSusun({
    required String noBongkarSusun,
    DateTime? tanggal,
    String? note,
  }) async {
    debugPrint(
        '✏️ [BONGKAR_SUSUN_VM] updateBongkarSusun(noBongkarSusun=$noBongkarSusun, tanggal=$tanggal, note=$note), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateBongkarSusun(
        noBongkarSusun: noBongkarSusun,
        tanggal: tanggal,
        note: note,
      );

      debugPrint(
          '✏️ [BONGKAR_SUSUN_VM] updateBongkarSusun success, noBongkarSusun=${updated.noBongkarSusun}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tanggal != null) {
          debugPrint(
              '✏️ [BONGKAR_SUSUN_VM] update in BY_DATE mode -> fetchByDate($tanggal), VM hash=$hashCode');
          await fetchByDate(tanggal);
        } else if (_date != null) {
          debugPrint(
              '✏️ [BONGKAR_SUSUN_VM] update in BY_DATE mode -> fetchByDate($_date), VM hash=$hashCode');
          await fetchByDate(_date!);
        } else {
          debugPrint(
              '✏️ [BONGKAR_SUSUN_VM] update in BY_DATE mode but no date known -> refreshPaged(), VM hash=$hashCode');
          refreshPaged();
        }
      } else {
        debugPrint(
            '✏️ [BONGKAR_SUSUN_VM] update in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [BONGKAR_SUSUN_VM] updateBongkarSusun error: $e, VM hash=$hashCode');
      debugPrint('❌ [BONGKAR_SUSUN_VM] updateBongkarSusun stack: $st');
      saveError = apiErrorMessage(e); // ✅ ini yang ditampilkan ke dialog
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ==============================
  // DELETE (DELETE /api/bongkar-susun/:noBongkarSusun)
  // ==============================
  Future<bool> deleteBongkarSusun(String noBongkarSusun) async {
    debugPrint('🗑 [BONGKAR_SUSUN_VM] deleteBongkarSusun(noBongkarSusun=$noBongkarSusun), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteBongkarSusun(noBongkarSusun);
      debugPrint('🗑 [BONGKAR_SUSUN_VM] deleteBongkarSusun success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      if (isByDateMode) {
        if (date != null) {
          debugPrint(
              '🗑 [BONGKAR_SUSUN_VM] delete in BY_DATE mode -> fetchByDate($date), VM hash=$hashCode');
          await fetchByDate(date!);
        }
      } else {
        debugPrint('🗑 [BONGKAR_SUSUN_VM] delete in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [BONGKAR_SUSUN_VM] deleteBongkarSusun error: $e, VM hash=$hashCode');
      debugPrint('❌ [BONGKAR_SUSUN_VM] deleteBongkarSusun stack: $st');

      String msg = e.toString().replaceFirst('Exception: ', '').trim();

      if (msg.startsWith('{') && msg.endsWith('}')) {
        try {
          final decoded = jsonDecode(msg);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {}
      }

      saveError = apiErrorMessage(e); // ✅ ini yang ditampilkan ke dialog
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    debugPrint('🔴 [BONGKAR_SUSUN_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}