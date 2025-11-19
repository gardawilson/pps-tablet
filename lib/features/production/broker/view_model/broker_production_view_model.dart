// lib/features/broker/view_model/broker_production_view_model.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/broker_production_repository.dart';
import '../model/broker_production_model.dart';
import '../model/broker_inputs_model.dart';

class BrokerProductionViewModel extends ChangeNotifier {
  final BrokerProductionRepository repository;

  BrokerProductionViewModel({required this.repository}) {
    pagingController = PagingController<int, BrokerProduction>(
      getNextPageKey: (state) =>
      state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPaged,
    );
  }

  // =========================
  // MODE BY DATE (TETAP)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<BrokerProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ====== CREATE STATE ======
  bool isSaving = false;
  String? saveError;

  // To prevent duplicate per-row inputs fetch
  final Map<String, Future<BrokerInputs>> _inflight = {};

  // =========================
  // MODE PAGED
  // =========================
  late final PagingController<int, BrokerProduction> pagingController;

  // Filters
  int pageSize = 20;

  /// Generic contains-search (backend searches **NoProduksi LIKE**)
  String _search = '';

  /// “Exact” NoProduksi (convenience). Backend still does LIKE; we keep this
  /// so UI can choose an exact flow (e.g., from a suggestion list).
  String? _noProduksi;
  bool _exactNoProduksi = false;

  int? _shift;
  DateTime? _date; // legacy single-day filter (mapped to dateFrom/dateTo in repo)

  String get search => _search;
  String? get noProduksi => _noProduksi;
  bool get exactNoProduksi => _exactNoProduksi;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ======================================================
  // INPUTS PER-ROW (cache, loading & error per NoProduksi)
  // ======================================================
  final Map<String, BrokerInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  bool isInputsLoading(String noProduksi) => _inputsLoading[noProduksi] == true;
  String? inputsError(String noProduksi) => _inputsError[noProduksi];
  BrokerInputs? inputsOf(String noProduksi) => _inputsCache[noProduksi];
  int inputsCount(String noProduksi, String key) =>
      _inputsCache[noProduksi]?.summary[key] ?? 0;


  void clearInputsCache([String? noProduksi]) {
    if (noProduksi == null) {
      _inputsCache.clear();
      _inputsLoading.clear();
      _inputsError.clear();
    } else {
      _inputsCache.remove(noProduksi);
      _inputsLoading.remove(noProduksi);
      _inputsError.remove(noProduksi);
    }
    notifyListeners();
  }

  // ===== BY DATE =====
  Future<void> fetchByDate(DateTime date) async {
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
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
  Future<List<BrokerProduction>> _fetchPaged(int pageKey) async {
    if (_isByDateMode) return const <BrokerProduction>[];

    // Decide what to send to repository:
    // - If exactNoProduksi = true => send via noProduksi (plus exact flag)
    // - Else if _noProduksi is set, send as generic search (contains)
    // - Else use _search
    final String? searchContains = _exactNoProduksi
        ? null
        : ((_noProduksi?.trim().isNotEmpty ?? false)
        ? _noProduksi!.trim()
        : (_search.trim().isNotEmpty ? _search.trim() : null));

    final String? noProduksiExact = _exactNoProduksi
        ? (_noProduksi?.trim().isNotEmpty == true ? _noProduksi!.trim() : null)
        : null;

    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: pageSize,
      search: searchContains,
      noProduksi: noProduksiExact,
      exactNoProduksi: _exactNoProduksi,
      shift: _shift,
      date: _date,
      // You can add dateFrom/dateTo/idMesin/idOperator pass-through here if needed
    );

    final items = res['items'] as List<BrokerProduction>;
    final totalPages = (res['totalPages'] as int?) ?? 1;

    if (pageKey > totalPages) return const <BrokerProduction>[];
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
    _exactNoProduksi = false;
    _noProduksi = null;
    if (search != null) _search = search;

    _shift = shift;
    _date = date;

    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoProduksi dengan contains (LIKE '%text%')
  void searchNoProduksiContains(String text) {
    _isByDateMode = false;
    _exactNoProduksi = false;
    _noProduksi = text;
    // Optional: keep _search in sync for UIs that only know 'search'
    _search = text;
    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  /// Cari NoProduksi exact (persis sama).
  /// Cocok untuk "Go to NoProduksi" atau saat user pilih dari suggestion list.
  void searchNoProduksiExact(String no) {
    _isByDateMode = false;
    _exactNoProduksi = true;
    _noProduksi = no;
    // _search intentionally not set to avoid duplicate params
    clearInputsCache();
    pagingController.refresh();
    notifyListeners();
  }

  void clearFilters() {
    _isByDateMode = false;
    _search = '';
    _noProduksi = null;
    _exactNoProduksi = false;
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

  // ===== Optional: Debounced search helper =====
  Timer? _searchDebounce;
  void setSearchDebounced(String text, {Duration delay = const Duration(milliseconds: 350)}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      applyFilters(search: text);
    });
  }



  // ====== CREATE / SAVE ======
  Future<BrokerProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jam, // int atau 'HH:mm-HH:mm'
    required int shift,
    String? hourStart,    // ⬅️ baru
    String? hourEnd,      // ⬅️ baru
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
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        jam: jam,
        shift: shift,
        hourStart: hourStart,   // ⬅️ lempar ke repo
        hourEnd: hourEnd,       // ⬅️ lempar ke repo
        checkBy1: checkBy1,
        checkBy2: checkBy2,
        approveBy: approveBy,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
      );

      // setelah create, refresh sesuai mode
      if (_isByDateMode) {
        await fetchByDate(tglProduksi);
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
  Future<BrokerProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jam, // int atau 'HH:mm-HH:mm'
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

      // setelah update, refresh sesuai mode
      if (_isByDateMode) {
        // kalau user lagi lihat per tanggal, kita ambil ulang tanggal itu
        if (tglProduksi != null) {
          await fetchByDate(tglProduksi);
        } else if (_date != null) {
          await fetchByDate(_date!);
        } else {
          // fallback: refresh paged aja
          clearInputsCache(noProduksi);
          pagingController.refresh();
        }
      } else {
        // mode paged
        clearInputsCache(noProduksi); // biar inputs row itu ke-refresh
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

  Future<bool> deleteProduksi(String noProduksi) async {
    try {
      saveError = null; // clear error sebelumnya
      notifyListeners();

      await repository.deleteProduksi(noProduksi);

      // refresh list
      if (isByDateMode) {
        if (date != null) {
          await fetchByDate(date!);
        }
      } else {
        clearInputsCache(noProduksi);
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
