import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/gilingan_production_repository.dart';
import '../model/gilingan_production_model.dart';

class GilinganProductionViewModel extends ChangeNotifier {
  final GilinganProductionRepository repository;

  // ✅ Constructor dengan optional repository parameter
  GilinganProductionViewModel({
    GilinganProductionRepository? repository,
  }) : repository = repository ?? GilinganProductionRepository() {
    debugPrint('🟢 [GILINGAN_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<GilinganProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================

  // ✅ Early initialization instead of lazy getter
  late final PagingController<int, GilinganProduction> _pagingController;
  PagingController<int, GilinganProduction> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint('🟢 [GILINGAN_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, GilinganProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [GILINGAN_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint('🟢 [GILINGAN_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [GILINGAN_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// "Exact" NoProduksi
  String? _noProduksi;
  bool _exactNoProduksi = false;

  int? _shift;
  DateTime? _date;

  String get search => _search;
  String? get noProduksi => _noProduksi;
  bool get exactNoProduksi => _exactNoProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ===== Helper lama kalau ada kode lain yang pakai =====
  void clear() {
    debugPrint('🧹 [GILINGAN_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [GILINGAN_VM] fetchByDate($date) dipanggil, VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [GILINGAN_VM] fetchByDate success, items length = ${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [GILINGAN_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [GILINGAN_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [GILINGAN_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<GilinganProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [GILINGAN_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [GILINGAN_VM] _fetchPaged: isByDateMode=true, return empty list, VM hash=$hashCode');
      return const <GilinganProduction>[];
    }

    final String? searchContains = _exactNoProduksi
        ? null
        : ((_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null));

    final String? noProduksiExact = _exactNoProduksi
        ? (_noProduksi?.trim().isNotEmpty == true ? _noProduksi!.trim() : null)
        : null;

    debugPrint(
        '📡 [GILINGAN_VM] _fetchPaged filters -> searchContains="$searchContains", noProduksiExact="$noProduksiExact", shift=$_shift, date=$_date, pageSize=$pageSize, VM hash=$hashCode');

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

      final items = res['items'] as List<GilinganProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [GILINGAN_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint('📡 [GILINGAN_VM] _fetchPaged: pageKey > totalPages, return empty, VM hash=$hashCode');
        return const <GilinganProduction>[];
      }

      debugPrint('📡 [GILINGAN_VM] _fetchPaged: returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [GILINGAN_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    int? shift,
    DateTime? date,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [GILINGAN_VM] applyFilters(search="$search", shift=$shift, date=$date, newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _exactNoProduksi = false;
    _noProduksi = null;
    if (search != null) _search = search;

    _shift = shift;
    _date = date;

    debugPrint('🔍 [GILINGAN_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();

    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint('🔍 [GILINGAN_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoProduksi = false;
    _noProduksi = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void searchNoProduksiExact(String no) {
    debugPrint('🔍 [GILINGAN_VM] searchNoProduksiExact("$no"), VM hash=$hashCode');
    _isByDateMode = false;
    _exactNoProduksi = true;
    _noProduksi = no;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [GILINGAN_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    _exactNoProduksi = false;
    _shift = null;
    _date = null;
    debugPrint('🧹 [GILINGAN_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [GILINGAN_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [GILINGAN_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint('🔄 [GILINGAN_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [GILINGAN_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [GILINGAN_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<GilinganProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required int shift,
    String? hourStart,
    String? hourEnd,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '🆕 [GILINGAN_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '🆕 [GILINGAN_VM] createProduksi success, noProduksi=${created?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint('🆕 [GILINGAN_VM] create in BY_DATE mode -> fetchByDate, VM hash=$hashCode');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [GILINGAN_VM] create in PAGED mode -> refreshPaged, VM hash=$hashCode');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [GILINGAN_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<GilinganProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    int? shift,
    String? hourStart,
    String? hourEnd,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '✏️ [GILINGAN_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noProduksi: noProduksi,
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '✏️ [GILINGAN_VM] updateProduksi success, noProduksi=${updated?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, tglProduksi!=null -> fetchByDate($tglProduksi), VM hash=$hashCode');
          await fetchByDate(tglProduksi);
        } else if (_date != null) {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, _date!=null -> fetchByDate($_date), VM hash=$hashCode');
          await fetchByDate(_date!);
        } else {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, no date info -> refreshPaged(), VM hash=$hashCode');
          refreshPaged();
        }
      } else {
        debugPrint(
            '✏️ [GILINGAN_VM] update in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [GILINGAN_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [GILINGAN_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [GILINGAN_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      if (isByDateMode) {
        if (date != null) {
          debugPrint(
              '🗑 [GILINGAN_VM] delete in BY_DATE mode -> fetchByDate($date), VM hash=$hashCode');
          await fetchByDate(date!);
        }
      } else {
        debugPrint('🗑 [GILINGAN_VM] delete in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [GILINGAN_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [GILINGAN_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}