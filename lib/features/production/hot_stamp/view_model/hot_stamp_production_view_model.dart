// lib/features/shared/hot_stamp_production/view_model/hot_stamp_production_view_model.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/hot_stamp_production_repository.dart';
import '../model/hot_stamp_production_model.dart';

class HotStampProductionViewModel extends ChangeNotifier {
  final HotStampProductionRepository repository;

  // ✅ Constructor dengan optional repository parameter
  HotStampProductionViewModel({
    HotStampProductionRepository? repository,
  }) : repository = repository ?? HotStampProductionRepository() {
    debugPrint('🟢 [HOTSTAMP_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<HotStampProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================

  // ✅ Early initialization instead of lazy getter
  late final PagingController<int, HotStampProduction> _pagingController;
  PagingController<int, HotStampProduction> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint('🟢 [HOTSTAMP_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, HotStampProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [HOTSTAMP_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint('🟢 [HOTSTAMP_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [HOTSTAMP_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoProduksi (untuk hot stamp, backend hanya support LIKE search)
  String? _noProduksi;

  String get search => _search;
  String? get noProduksi => _noProduksi;

  // ===== Helper lama kalau ada kode lain yang pakai =====
  void clear() {
    debugPrint('🧹 [HOTSTAMP_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [HOTSTAMP_VM] fetchByDate($date) dipanggil, VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [HOTSTAMP_VM] fetchByDate success, items length = ${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [HOTSTAMP_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [HOTSTAMP_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [HOTSTAMP_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [HOTSTAMP_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<HotStampProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [HOTSTAMP_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [HOTSTAMP_VM] _fetchPaged: isByDateMode=true, return empty list, VM hash=$hashCode');
      return const <HotStampProduction>[];
    }

    // Hot stamp backend hanya support search (LIKE NoProduksi)
    final String? searchQuery = (_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
        '📡 [HOTSTAMP_VM] _fetchPaged filters -> search="$searchQuery", pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
      );

      final items = res['items'] as List<HotStampProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [HOTSTAMP_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint('📡 [HOTSTAMP_VM] _fetchPaged: pageKey > totalPages, return empty, VM hash=$hashCode');
        return const <HotStampProduction>[];
      }

      debugPrint('📡 [HOTSTAMP_VM] _fetchPaged: returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [HOTSTAMP_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [HOTSTAMP_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [HOTSTAMP_VM] applyFilters(search="$search", newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noProduksi = null;
    if (search != null) _search = search;

    debugPrint('🔍 [HOTSTAMP_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();

    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint('🔍 [HOTSTAMP_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _noProduksi = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [HOTSTAMP_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    debugPrint('🧹 [HOTSTAMP_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [HOTSTAMP_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [HOTSTAMP_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint('🔄 [HOTSTAMP_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [HOTSTAMP_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [HOTSTAMP_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<HotStampProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jam, // int or String ('HH:mm-HH:mm')
    required int shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    debugPrint(
        '🆕 [HOTSTAMP_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, hourMeter=$hourMeter), VM hash=$hashCode');
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
        hourMeter: hourMeter,
      );

      debugPrint(
          '🆕 [HOTSTAMP_VM] createProduksi success, noProduksi=${created?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint('🆕 [HOTSTAMP_VM] create in BY_DATE mode -> fetchByDate, VM hash=$hashCode');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [HOTSTAMP_VM] create in PAGED mode -> refreshPaged, VM hash=$hashCode');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [HOTSTAMP_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [HOTSTAMP_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<HotStampProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jam,
    int? shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    double? hourMeter,
  }) async {
    debugPrint(
        '✏️ [HOTSTAMP_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, hourMeter=$hourMeter), VM hash=$hashCode');
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
        hourMeter: hourMeter,
      );

      debugPrint(
          '✏️ [HOTSTAMP_VM] updateProduksi success, noProduksi=${updated?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint(
              '✏️ [HOTSTAMP_VM] update in BY_DATE mode, tglProduksi!=null -> fetchByDate($tglProduksi), VM hash=$hashCode');
          await fetchByDate(tglProduksi);
        } else {
          debugPrint(
              '✏️ [HOTSTAMP_VM] update in BY_DATE mode, no tglProduksi -> refreshPaged(), VM hash=$hashCode');
          refreshPaged();
        }
      } else {
        debugPrint(
            '✏️ [HOTSTAMP_VM] update in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [HOTSTAMP_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [HOTSTAMP_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [HOTSTAMP_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [HOTSTAMP_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      if (isByDateMode) {
        debugPrint('🗑 [HOTSTAMP_VM] delete in BY_DATE mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      } else {
        debugPrint('🗑 [HOTSTAMP_VM] delete in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [HOTSTAMP_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [HOTSTAMP_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [HOTSTAMP_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}