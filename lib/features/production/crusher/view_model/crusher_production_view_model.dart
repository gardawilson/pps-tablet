// lib/features/production/crusher/view_model/crusher_production_view_model.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/crusher_production_repository.dart';
import '../model/crusher_production_model.dart';
import '../model/crusher_inputs_model.dart';

class CrusherProductionViewModel extends ChangeNotifier {
  final CrusherProductionRepository repository;

  CrusherProductionViewModel({required this.repository}) {
    pagingController = PagingController<int, CrusherProduction>(
      getNextPageKey: (state) =>
      state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPaged,
    );
  }

  // =========================
  // MODE BY DATE (untuk dropdown)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<CrusherProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE STATE ======
  bool isSaving = false;
  String? saveError;

  // To prevent duplicate per-row inputs fetch
  final Map<String, Future<CrusherInputs>> _inflight = {};

  // =========================
  // MODE PAGED
  // =========================
  late final PagingController<int, CrusherProduction> pagingController;

  // Filters
  int pageSize = 20;

  /// Generic contains-search (backend searches **NoCrusherProduksi LIKE**)
  String _search = '';

  /// "Exact" NoCrusherProduksi (convenience). Backend still does LIKE; we keep this
  /// so UI can choose an exact flow (e.g., from a suggestion list).
  String? _noCrusherProduksi;
  bool _exactNoCrusherProduksi = false;

  int? _shift;
  DateTime? _date; // legacy single-day filter (mapped to dateFrom/dateTo in repo)

  String get search => _search;
  String? get noCrusherProduksi => _noCrusherProduksi;
  bool get exactNoCrusherProduksi => _exactNoCrusherProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ======================================================
  // INPUTS PER-ROW (cache, loading & error per NoCrusherProduksi)
  // ======================================================
  final Map<String, CrusherInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noCrusherProduksi) => _inputsLoading[noCrusherProduksi] == true;
  String? inputsError(String noCrusherProduksi) => _inputsError[noCrusherProduksi];
  CrusherInputs? inputsOf(String noCrusherProduksi) => _inputsCache[noCrusherProduksi];
  int inputsCount(String noCrusherProduksi, String key) =>
      _inputsCache[noCrusherProduksi]?.summary[key] ?? 0;

  void clearInputsCache([String? noCrusherProduksi]) {
    if (noCrusherProduksi == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      _inputsCache.remove(noCrusherProduksi);
      _inputsLoading.remove(noCrusherProduksi);
      _inputsError.remove(noCrusherProduksi);
    }
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(
      DateTime date, {
        int? idMesin,
        String? shift,
      }) async {
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(
        date,
        idMesin: idMesin,
        shift: shift,
      );
      items = data;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void exitByDateModeAndRefreshPaged() {
    if (_isByDateMode) {
      _isByDateMode = false;
      items = [];
      error = '';
      isLoading = false;
      pagingController.refresh();
      notifyListeners();
    }
  }

  // ====== FETCH per halaman (PagingController v5) ======
  Future<List<CrusherProduction>> _fetchPaged(int pageKey) async {
    if (_isByDateMode) return const <CrusherProduction>[];

    // Decide what to send to repository:
    // - If exactNoCrusherProduksi = true => send via noCrusherProduksi (plus exact flag)
    // - Else if _noCrusherProduksi is set, send as generic search (contains)
    // - Else use _search
    final String? searchContains = _exactNoCrusherProduksi
        ? null
        : ((_noCrusherProduksi?.trim().isNotEmpty ?? false)
        ? _noCrusherProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null));

    final String? noCrusherProduksiExact = _exactNoCrusherProduksi
        ? (_noCrusherProduksi?.trim().isNotEmpty == true ? _noCrusherProduksi!.trim() : null)
        : null;

    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: pageSize,
      search: searchContains,
      noCrusherProduksi: noCrusherProduksiExact,
      exactNoCrusherProduksi: _exactNoCrusherProduksi,
      shift: _shift,
      date: _date,
      // You can add dateFrom/dateTo/idMesin/idOperator pass-through here if needed
    );

    final items = res['items'] as List<CrusherProduction>;
    final totalPages = (res['totalPages'] as int?) ?? 1;

    if (pageKey > totalPages) return const <CrusherProduction>[];
    return items;
  }

  // ====== Filter helpers (mode paged) ======

  /// Pencarian generic (contains). Dipakai action bar search biasa.
  void applyFilters({
    String? search,
    int? shift,
    DateTime? date,
    int? newPageSize,
  }) {
    _isByDateMode = false;
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;

    // mode contains (reset exact)
    _exactNoCrusherProduksi = false;
    _noCrusherProduksi = null;
    if (search != null) _search = search;

    _shift = shift;
    _date = date;

    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoCrusherProduksi dengan contains (LIKE '%text%')
  void searchNoCrusherProduksiContains(String text) {
    _isByDateMode = false;
    _exactNoCrusherProduksi = false;
    _noCrusherProduksi = text;
    // Optional: keep _search in sync for UIs that only know 'search'
    _search = text;
    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoCrusherProduksi exact (persis sama).
  /// Cocok untuk "Go to NoCrusherProduksi" atau saat user pilih dari suggestion list.
  void searchNoCrusherProduksiExact(String no) {
    _isByDateMode = false;
    _exactNoCrusherProduksi = true;
    _noCrusherProduksi = no;
    // _search intentionally not set to avoid duplicate params
    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    _isByDateMode = false;
    _search = '';
    _noCrusherProduksi = null;
    _exactNoCrusherProduksi = false;
    _shift = null;
    _date = null;

    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    _isByDateMode = false;
    clearInputsCache();
    pagingController.refresh();
  }

  void clear() {
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(String text, {Duration delay = const Duration(milliseconds: 350)}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<CrusherProduction?> createProduksi({
    required DateTime tanggal,
    required int idMesin,
    required int idOperator,
    required int jamKerja,
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
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
        tanggal: tanggal,
        idMesin: idMesin,
        idOperator: idOperator,
        jamKerja: jamKerja,
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

      // setelah create, refresh sesuai mode
      if (_isByDateMode) {
        await fetchByDate(tanggal);
      } else {
        clearInputsCache();
        pagingController.refresh();
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
  Future<CrusherProduction?> updateProduksi({
    required String noCrusherProduksi,
    DateTime? tanggal,
    int? idMesin,
    int? idOperator,
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
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final updated = await repository.updateProduksi(
        noCrusherProduksi: noCrusherProduksi,
        tanggal: tanggal,
        idMesin: idMesin,
        idOperator: idOperator,
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

      // setelah update, refresh sesuai mode
      if (_isByDateMode) {
        // kalau user lagi lihat per tanggal, kita ambil ulang tanggal itu
        if (tanggal != null) {
          await fetchByDate(tanggal);
        } else if (_date != null) {
          await fetchByDate(_date!);
        } else {
          // fallback: refresh paged aja
          clearInputsCache(noCrusherProduksi);
          pagingController.refresh();
        }
      } else {
        // mode paged
        clearInputsCache(noCrusherProduksi); // biar inputs row itu ke-refresh
        pagingController.refresh();
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


  Future<bool> deleteProduksi(String noCrusherProduksi) async {
    try {
      saveError = null; // clear error sebelumnya
      notifyListeners();

      await repository.deleteProduksi(noCrusherProduksi);

      // refresh list
      if (isByDateMode) {
        if (date != null) {
          await fetchByDate(date!);
        }
      } else {
        clearInputsCache(noCrusherProduksi);
        pagingController.refresh();
      }
      return true;
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '').trim();

      // 🔍 kalau msg kelihatan seperti JSON → coba ambil "message"
      if (msg.startsWith('{') && msg.endsWith('}')) {
        try {
          final decoded = jsonDecode(msg);
          if (decoded is Map && decoded['message'] != null) {
            msg = decoded['message'].toString();
          }
        } catch (_) {
          // kalau parsing gagal, biarkan msg apa adanya
        }
      }

      saveError = msg;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    pagingController.dispose();
    super.dispose();
  }
}