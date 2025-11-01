// lib/features/shared/washing_production/view_model/washing_production_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../repository/washing_production_repository.dart';
import '../model/washing_production_model.dart';

class WashingProductionViewModel extends ChangeNotifier {
  final WashingProductionRepository repository;
  WashingProductionViewModel({required this.repository}) {
    // PagingController v5: definisikan cara ambil page & cara hitung next key
    pagingController = PagingController<int, WashingProduction>(
      // Stop bila halaman terakhir KOSONG; selain itu naikan int key otomatis
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
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
  bool isFetchingMore = false; // tidak dipakai di by-date, dibiarkan demi kompatibilitas UI lama
  String error = '';

  // =========================
  // MODE PAGED (V5)
  // =========================
  late final PagingController<int, WashingProduction> pagingController;

  // Filter/param untuk mode paged
  int pageSize = 20;
  String _search = '';
  int? _shift;
  DateTime? _date;

  String get search => _search;
  int? get shift => _shift;
  DateTime? get date => _date;

  // ===== BY DATE: JANGAN DIUBAH =====
  Future<void> fetchByDate(DateTime date) async {
    _isByDateMode = true;
    isLoading = true; error = ''; notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      items = data;
      // Reset konteks paging (tidak relevan di by-date)
      // _page dsb. sudah tidak dipakai; cukup tampilkan items.length
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
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

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }
}
