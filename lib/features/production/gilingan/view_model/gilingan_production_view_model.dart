import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/gilingan_production_repository.dart';
import '../model/gilingan_production_model.dart';

class GilinganProductionViewModel extends ChangeNotifier {
  final GilinganProductionRepository repository;

  GilinganProductionViewModel({required this.repository}) {
    debugPrint('🟢 [GILINGAN_VM] ctor called, repository: $repository');
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

  // 👉 BACKING FIELD + LAZY GETTER
  PagingController<int, GilinganProduction>? _pagingController;

  PagingController<int, GilinganProduction> get pagingController {
    if (_pagingController != null) {
      return _pagingController!;
    }

    debugPrint('🟢 [GILINGAN_VM] lazy init pagingController');

    _pagingController = PagingController<int, GilinganProduction>(
      getNextPageKey: (state) =>
      state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPaged,
    );

    debugPrint(
      '🟢 [GILINGAN_VM] pagingController created: $_pagingController (hash=${_pagingController.hashCode})',
    );

    return _pagingController!;
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// “Exact” NoProduksi
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
    debugPrint('🧹 [GILINGAN_VM] clear() dipanggil');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [GILINGAN_VM] fetchByDate($date) dipanggil');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [GILINGAN_VM] fetchByDate success, items length = ${data.length}');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] fetchByDate error: $e');
      debugPrint('❌ [GILINGAN_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [GILINGAN_VM] exitByDateModeAndRefreshPaged()');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      if (_pagingController != null) {
        debugPrint(
            '🔁 [GILINGAN_VM] exitByDateMode -> pagingController.refresh()');
        _pagingController!.refresh();
      } else {
        debugPrint(
            '⚠️ [GILINGAN_VM] exitByDateMode: pagingController masih null, skip refresh');
      }
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<GilinganProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [GILINGAN_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, pagingController.hash=${_pagingController?.hashCode}');

    if (_isByDateMode) {
      debugPrint(
          '📡 [GILINGAN_VM] _fetchPaged: isByDateMode=true, return empty list');
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
        '📡 [GILINGAN_VM] _fetchPaged filters -> searchContains="$searchContains", noProduksiExact="$noProduksiExact", shift=$_shift, date=$_date, pageSize=$pageSize');

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
          '📡 [GILINGAN_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey');

      if (pageKey > totalPages) {
        debugPrint(
            '📡 [GILINGAN_VM] _fetchPaged: pageKey > totalPages, return empty');
        return const <GilinganProduction>[];
      }
      return items;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] _fetchPaged error: $e');
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
        '🔍 [GILINGAN_VM] applyFilters(search="$search", shift=$shift, date=$date, newPageSize=$newPageSize)');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _exactNoProduksi = false;
    _noProduksi = null;
    if (search != null) _search = search;

    _shift = shift;
    _date = date;

    if (_pagingController != null) {
      debugPrint(
          '🔍 [GILINGAN_VM] applyFilters -> pagingController.refresh()');
      _pagingController!.refresh();
    } else {
      debugPrint(
          '⚠️ [GILINGAN_VM] applyFilters: pagingController masih null, akan dibuat saat pertama kali dibutuhkan oleh widget');
    }

    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint('🔍 [GILINGAN_VM] searchNoProduksiContains("$text")');
    _isByDateMode = false;
    _exactNoProduksi = false;
    _noProduksi = text;
    _search = text;

    if (_pagingController != null) {
      _pagingController!.refresh();
    }
    notifyListeners();
  }

  void searchNoProduksiExact(String no) {
    debugPrint('🔍 [GILINGAN_VM] searchNoProduksiExact("$no")');
    _isByDateMode = false;
    _exactNoProduksi = true;
    _noProduksi = no;

    if (_pagingController != null) {
      _pagingController!.refresh();
    }
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [GILINGAN_VM] clearFilters()');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    _exactNoProduksi = false;
    _shift = null;
    _date = null;

    if (_pagingController != null) {
      _pagingController!.refresh();
    }
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint(
        '🔄 [GILINGAN_VM] refreshPaged() called, isByDateMode=$_isByDateMode, pagingController.hash=${_pagingController?.hashCode}');
    _isByDateMode = false;
    if (_pagingController != null) {
      _pagingController!.refresh();
    } else {
      debugPrint(
          '⚠️ [GILINGAN_VM] refreshPaged() dipanggil tapi pagingController masih null (belum pernah dipakai di UI). Tidak apa-apa, nanti widget pertama kali build akan memicu fetch.');
    }
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [GILINGAN_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms)');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [GILINGAN_VM] debounce fired, applyFilters("$text")');
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
        '🆕 [GILINGAN_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter)');
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
          '🆕 [GILINGAN_VM] createProduksi success, noProduksi=${created?.noProduksi}');

      if (_isByDateMode) {
        debugPrint('🆕 [GILINGAN_VM] create in BY_DATE mode -> fetchByDate');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [GILINGAN_VM] create in PAGED mode -> refreshPaged');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] createProduksi error: $e');
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
        '✏️ [GILINGAN_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter)');
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
          '✏️ [GILINGAN_VM] updateProduksi success, noProduksi=${updated?.noProduksi}');

      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, tglProduksi!=null -> fetchByDate($tglProduksi)');
          await fetchByDate(tglProduksi);
        } else if (_date != null) {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, _date!=null -> fetchByDate($_date)');
          await fetchByDate(_date!);
        } else {
          debugPrint(
              '✏️ [GILINGAN_VM] update in BY_DATE mode, no date info -> refreshPaged()');
          refreshPaged();
        }
      } else {
        debugPrint(
            '✏️ [GILINGAN_VM] update in PAGED mode -> refreshPaged()');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] updateProduksi error: $e');
      debugPrint('❌ [GILINGAN_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [GILINGAN_VM] deleteProduksi(noProduksi=$noProduksi)');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [GILINGAN_VM] deleteProduksi success');

      if (isByDateMode) {
        if (date != null) {
          debugPrint(
              '🗑 [GILINGAN_VM] delete in BY_DATE mode -> fetchByDate($date)');
          await fetchByDate(date!);
        }
      } else {
        debugPrint('🗑 [GILINGAN_VM] delete in PAGED mode -> refreshPaged()');
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [GILINGAN_VM] deleteProduksi error: $e');
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
    debugPrint(
        '🧹 [GILINGAN_VM] dispose() dipanggil, pagingController.hash=${_pagingController?.hashCode}');
    _searchDebounce?.cancel();
    _pagingController?.dispose();
    super.dispose();
  }
}
