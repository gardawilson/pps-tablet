// lib/features/shared/washing_production/view_model/washing_production_view_model.dart
import 'dart:async'; // ⬅️ untuk Timer (debounce)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/washing_inputs_model.dart';
import '../repository/washing_production_repository.dart';
import '../model/washing_production_model.dart';

class WashingProductionViewModel extends ChangeNotifier {
  final WashingProductionRepository repository;

  WashingProductionViewModel({required this.repository}) {
    // PagingController v5: definisikan cara ambil page & cara hitung next key
    pagingController = PagingController<int, WashingProduction>(
      // Stop bila halaman terakhir KOSONG; selain itu naikan int key otomatis
      getNextPageKey: (state) =>
      state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPaged, // callback ambil data per halaman
    );
  }

  // =========================
  // MODE BY DATE (TETAP)
  // =========================
  bool _isByDateMode = false;
  bool get isByDateMode => _isByDateMode;

  List<WashingProduction> items = [];
  bool isLoading = false;
  bool isFetchingMore =
  false; // tidak dipakai di by-date, dibiarkan demi kompatibilitas UI lama
  String error = '';

  // =========================
  // STATE CREATE
  // =========================
  bool isSaving = false;
  String? saveError;

  // =========================
  // MODE PAGED (V5)
  // =========================
  late final PagingController<int, WashingProduction> pagingController;

  // Filter/param untuk mode paged
  int pageSize = 20;
  String _search = '';
  int? _shift;
  DateTime? _date;

  // ======================================================
  // INPUTS PER-ROW (cache, loading & error per NoProduksi)
  // ======================================================
  final Map<String, WashingInputs> _inputsCache = {};
  final Map<String, bool> _inputsLoading = {};
  final Map<String, String?> _inputsError = {};

  String get search => _search;
  int? get shift => _shift;
  DateTime? get date => _date;

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

  // ===== BY DATE: JANGAN DIUBAH =====
  Future<void> fetchByDate(DateTime date) async {
    _isByDateMode = true;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      items = data;
      // Reset konteks paging (tidak relevan di by-date)
      // _page dsb. sudah tidak dipakai; cukup tampilkan items.length
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Keluar dari mode by-date → kembali ke paged dan refresh dari page 1.
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

  // ====== FETCH PER HALAMAN (dipanggil otomatis oleh PagingController v5) ======
  Future<List<WashingProduction>> _fetchPaged(int pageKey) async {
    // Jika screen sedang menampilkan by-date (ListView biasa), biarkan kosong.
    if (_isByDateMode) return const <WashingProduction>[];

    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: pageSize,
      search: _search.isEmpty ? null : _search,
      shift: _shift,
      date: _date,
    );

    final items = res['items'] as List<WashingProduction>;
    final totalPages = (res['totalPages'] as int?) ?? 1;

    // Pola v5: hentikan dengan mengembalikan [] pada request SETELAH halaman terakhir.
    // Jadi: saat last page (pageKey == totalPages), kita tetap return items.
    // Saat library minta page berikutnya (pageKey+1 > totalPages), kita return [].
    if (pageKey > totalPages) return const <WashingProduction>[];

    return items; // library akan minta next page menurut getNextPageKey()
  }

  // ====== Filters utk mode paged ======
  void applyFilters({
    String? search,
    int? shift,
    DateTime? date,
    int? newPageSize,
  }) {
    _isByDateMode = false; // pastikan di mode paged
    if (newPageSize != null && newPageSize > 0) pageSize = newPageSize;
    if (search != null) _search = search;
    _shift = shift;
    _date = date;
    pagingController.refresh(); // mulai lagi dari pageKey pertama
    notifyListeners();
  }

  void clearFilters() {
    _isByDateMode = false;
    _search = '';
    _shift = null;
    _date = null;
    pagingController.refresh();
    notifyListeners();
  }

  void refreshPaged() {
    _isByDateMode = false;
    pagingController.refresh();
  }

  // ===== Optional: Debounced search helper (dipakai di ActionBar washing) =====
  Timer? _searchDebounce;

  void setSearchDebounced(
      String text, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(delay, () {
      applyFilters(search: text);
    });
  }

  // ====== CREATE / SAVE ======
  Future<WashingProduction?> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    /// Bisa int (jam) atau 'HH:mm-HH:mm'
    required dynamic jamKerja,
    required int shift,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,

    // ⬇️ baru: ikuti repository
    String? hourStart,
    String? hourEnd,
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      final created = await repository.createProduksi(
        tglProduksi: tglProduksi,
        idMesin: idMesin,
        idOperator: idOperator,
        jamKerja: jamKerja,
        shift: shift,
        checkBy1: checkBy1,
        checkBy2: checkBy2,
        approveBy: approveBy,
        jmlhAnggota: jmlhAnggota,
        hadir: hadir,
        hourMeter: hourMeter,
        // ⬇️ lempar ke repo
        hourStart: hourStart,
        hourEnd: hourEnd,
      );

      // setelah create, refresh sesuai mode
      if (_isByDateMode) {
        await fetchByDate(tglProduksi);
      } else {
        refreshPaged();
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
  /// Update existing Washing Production header
  ///
  /// Parameters sama dengan broker KECUALI:
  /// - jamKerja (bukan jam) - sesuai field di WashingProduksi_h
  ///
  /// Returns updated WashingProduction or null on error
  Future<WashingProduction?> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jamKerja, // ⚠️ PERBEDAAN: jamKerja (bukan jam)
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
