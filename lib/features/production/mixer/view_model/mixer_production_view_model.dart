// lib/features/shared/mixer_production/view_model/mixer_production_view_model.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/mixer_production_repository.dart';
import '../model/mixer_production_model.dart';

class MixerProductionViewModel extends ChangeNotifier {
  final MixerProductionRepository repository;

  // ✅ Constructor dengan optional repository parameter
  MixerProductionViewModel({
    MixerProductionRepository? repository,
  }) : repository = repository ?? MixerProductionRepository() {
    debugPrint('🟢 [MIXER_VM] ctor called, repository: ${this.repository}, VM hash=$hashCode');
    _initializePagingController();
  }

  // =========================
  // MODE BY DATE (opsional)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<MixerProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE / UPDATE / DELETE STATE ======
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (TABLE)
  // =========================

  // ✅ Early initialization instead of lazy getter
  late final PagingController<int, MixerProduction> _pagingController;
  PagingController<int, MixerProduction> get pagingController => _pagingController;

  void _initializePagingController() {
    debugPrint('🟢 [MIXER_VM] _initializePagingController: creating controller, VM hash=$hashCode');

    _pagingController = PagingController<int, MixerProduction>(
      getNextPageKey: (state) {
        debugPrint('🟢 [MIXER_VM] getNextPageKey called, VM hash=$hashCode');
        return state.lastPageIsEmpty ? null : state.nextIntPageKey;
      },
      fetchPage: (pageKey) {
        debugPrint('🟢 [MIXER_VM] fetchPage wrapper called for pageKey=$pageKey, VM hash=$hashCode');
        return _fetchPaged(pageKey);
      },
    );

    debugPrint(
      '🟢 [MIXER_VM] pagingController created: hash=${_pagingController.hashCode}, VM hash=$hashCode',
    );
  }

  // Filters
  int pageSize = 20;

  /// Generic contains-search
  String _search = '';

  /// NoProduksi (untuk mixer, backend hanya support LIKE search)
  String? _noProduksi;

  String get search => _search;
  String? get noProduksi => _noProduksi;

  // ===== Helper lama kalau ada kode lain yang pakai =====
  void clear() {
    debugPrint('🧹 [MIXER_VM] clear() dipanggil, VM hash=$hashCode');
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    debugPrint('📅 [MIXER_VM] fetchByDate($date) dipanggil, VM hash=$hashCode');
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      debugPrint(
          '📅 [MIXER_VM] fetchByDate success, items length = ${data.length}, VM hash=$hashCode');
      items = data;
    } catch (e, st) {
      debugPrint('❌ [MIXER_VM] fetchByDate error: $e, VM hash=$hashCode');
      debugPrint('❌ [MIXER_VM] fetchByDate stack: $st');
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    debugPrint('🔁 [MIXER_VM] exitByDateModeAndRefreshPaged(), VM hash=$hashCode');
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      debugPrint('🔁 [MIXER_VM] exitByDateMode -> pagingController.refresh(), VM hash=$hashCode');
      _pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<MixerProduction>> _fetchPaged(int pageKey) async {
    debugPrint(
        '📡 [MIXER_VM] _fetchPaged(pageKey=$pageKey), isByDateMode=$_isByDateMode, VM hash=$hashCode');

    if (_isByDateMode) {
      debugPrint('📡 [MIXER_VM] _fetchPaged: isByDateMode=true, return empty list, VM hash=$hashCode');
      return const <MixerProduction>[];
    }

    // Mixer backend hanya support search (LIKE NoProduksi)
    final String? searchQuery = (_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null);

    debugPrint(
        '📡 [MIXER_VM] _fetchPaged filters -> search="$searchQuery", pageSize=$pageSize, VM hash=$hashCode');

    try {
      final res = await repository.fetchAll(
        page: pageKey,
        pageSize: pageSize,
        search: searchQuery,
      );

      final items = res['items'] as List<MixerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;

      debugPrint(
          '📡 [MIXER_VM] _fetchPaged result: items.length=${items.length}, totalPages=$totalPages, currentPage=$pageKey, VM hash=$hashCode');

      if (pageKey > totalPages) {
        debugPrint('📡 [MIXER_VM] _fetchPaged: pageKey > totalPages, return empty, VM hash=$hashCode');
        return const <MixerProduction>[];
      }

      debugPrint('📡 [MIXER_VM] _fetchPaged: returning ${items.length} items, VM hash=$hashCode');
      return items;
    } catch (e, st) {
      debugPrint('❌ [MIXER_VM] _fetchPaged error: $e, VM hash=$hashCode');
      debugPrint('❌ [MIXER_VM] _fetchPaged stack: $st');
      rethrow;
    }
  }

  // ====== Filter helpers (mode paged) ======
  void applyFilters({
    String? search,
    int? newPageSize,
  }) {
    debugPrint(
        '🔍 [MIXER_VM] applyFilters(search="$search", newPageSize=$newPageSize), VM hash=$hashCode');
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    _noProduksi = null;
    if (search != null) _search = search;

    debugPrint('🔍 [MIXER_VM] applyFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();

    notifyListeners();
  }

  void searchNoProduksiContains(String text) {
    debugPrint('🔍 [MIXER_VM] searchNoProduksiContains("$text"), VM hash=$hashCode');
    _isByDateMode = false;
    _noProduksi = text;
    _search = text;
    _pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    debugPrint('🧹 [MIXER_VM] clearFilters(), VM hash=$hashCode');
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    debugPrint('🧹 [MIXER_VM] clearFilters -> pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    debugPrint('🔄 [MIXER_VM] refreshPaged() called, VM hash=$hashCode');
    _isByDateMode = false;
    debugPrint('🔄 [MIXER_VM] Calling _pagingController.refresh(), VM hash=$hashCode');
    _pagingController.refresh();
    debugPrint('🔄 [MIXER_VM] _pagingController.refresh() completed, VM hash=$hashCode');
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    debugPrint(
        '⌛ [MIXER_VM] setSearchDebounced("$text", delay=${delay.inMilliseconds}ms), VM hash=$hashCode');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      debugPrint('⌛ [MIXER_VM] debounce fired, applyFilters("$text"), VM hash=$hashCode');
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<MixerProduction?> createProduksi({
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
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '🆕 [MIXER_VM] createProduksi(tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
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
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '🆕 [MIXER_VM] createProduksi success, noProduksi=${created?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH CREATE
      if (_isByDateMode) {
        debugPrint('🆕 [MIXER_VM] create in BY_DATE mode -> fetchByDate, VM hash=$hashCode');
        await fetchByDate(tglProduksi);
      } else {
        debugPrint('🆕 [MIXER_VM] create in PAGED mode -> refreshPaged, VM hash=$hashCode');
        refreshPaged();
      }

      return created;
    } catch (e, st) {
      debugPrint('❌ [MIXER_VM] createProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [MIXER_VM] createProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== UPDATE / SAVE ======
  Future<MixerProduction?> updateProduksi({
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
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    debugPrint(
        '✏️ [MIXER_VM] updateProduksi(noProduksi=$noProduksi, tglProduksi=$tglProduksi, idMesin=$idMesin, idOperator=$idOperator, jam=$jam, shift=$shift, hourStart=$hourStart, hourEnd=$hourEnd, jmlhAnggota=$jmlhAnggota, hadir=$hadir, hourMeter=$hourMeter), VM hash=$hashCode');
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
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      debugPrint(
          '✏️ [MIXER_VM] updateProduksi success, noProduksi=${updated?.noProduksi}, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH UPDATE
      if (_isByDateMode) {
        if (tglProduksi != null) {
          debugPrint(
              '✏️ [MIXER_VM] update in BY_DATE mode, tglProduksi!=null -> fetchByDate($tglProduksi), VM hash=$hashCode');
          await fetchByDate(tglProduksi);
        } else {
          debugPrint(
              '✏️ [MIXER_VM] update in BY_DATE mode, no tglProduksi -> refreshPaged(), VM hash=$hashCode');
          refreshPaged();
        }
      } else {
        debugPrint(
            '✏️ [MIXER_VM] update in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }

      return updated;
    } catch (e, st) {
      debugPrint('❌ [MIXER_VM] updateProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [MIXER_VM] updateProduksi stack: $st');
      saveError = e.toString();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ====== CREATE V2 (multi-operator + outputJenisId + idRegu) ======
  Future<MixerProduction?> createProduksiWithJenis({
    required DateTime tglProduksi,
    required int idMesin,
    required List<int> idOperators,
    required int outputJenisId,
    required int shift,
    String? hourStart,
    String? hourEnd,
    int? idRegu,
    int? hadir,
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksiWithJenis(
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperators: idOperators,
        outputJenisId: outputJenisId,
        shift: shift,
        hourStart: hourStart,
        hourEnd: hourEnd,
        idRegu: idRegu,
        hadir: hadir,
      );

      if (_isByDateMode) {
        await fetchByDate(tglProduksi);
      } else {
        refreshPaged();
      }

      return created;
    } catch (e) {
      saveError = e.toString().replaceFirst('Exception: ', '').trim();
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduksi(String noProduksi) async {
    debugPrint('🗑 [MIXER_VM] deleteProduksi(noProduksi=$noProduksi), VM hash=$hashCode');
    try {
      saveError = null;
      notifyListeners();

      await repository.deleteProduksi(noProduksi);
      debugPrint('🗑 [MIXER_VM] deleteProduksi success, VM hash=$hashCode');

      // 🔄 AUTO REFRESH LIST SETELAH DELETE
      if (isByDateMode) {
        debugPrint('🗑 [MIXER_VM] delete in BY_DATE mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      } else {
        debugPrint('🗑 [MIXER_VM] delete in PAGED mode -> refreshPaged(), VM hash=$hashCode');
        refreshPaged();
      }
      return true;
    } catch (e, st) {
      debugPrint('❌ [MIXER_VM] deleteProduksi error: $e, VM hash=$hashCode');
      debugPrint('❌ [MIXER_VM] deleteProduksi stack: $st');

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
    debugPrint('🔴 [MIXER_VM] dispose() dipanggil, VM hash=$hashCode');
    _searchDebounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}