import 'package:flutter/material.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';
import '../repository/washing_repository.dart';
import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../shared/plastic_type/jenis_plastik_repository.dart';

class WashingViewModel extends ChangeNotifier {
  final WashingRepository repository;

  WashingViewModel({required this.repository});

  // === HEADER STATE ===
  List<WashingHeader> items = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int _page = 1;
  int _totalPages = 1;
  String _search = '';

  // === DETAIL STATE ===
  String? selectedNoWashing; // ⬅️ satu-satunya sumber highlight
  List<WashingDetail> details = [];
  bool isDetailLoading = false;
  String detailError = '';

  // === JENIS PLASTIK STATE ===
  final JenisPlastikRepository jenisRepo = JenisPlastikRepository();
  List<JenisPlastik> jenisList = [];
  JenisPlastik? selectedJenisPlastik;
  bool isJenisLoading = false;
  String jenisError = '';

  String? lastCreatedNoWashing;

  // =============================
  //  Highlight helpers
  // =============================

  /// Set / pindahkan highlight ke [no] (atau null untuk clear) tanpa memuat detail.
  void setSelectedNoWashing(String? no) { // ⬅️ baru
    if (selectedNoWashing == no) return;
    selectedNoWashing = no;
    notifyListeners();
  }

  // WashingViewModel
  Future<void> loadJenisPlastik({int? preselectId}) async {
    isJenisLoading = true;
    jenisError = '';
    notifyListeners();

    try {
      final list = await jenisRepo.fetchAll(onlyActive: true);

      // Dedupe by id
      final byId = <int, JenisPlastik>{};
      for (final e in list) {
        byId[e.idJenisPlastik] = e;
      }
      jenisList = byId.values.toList();

      if (preselectId != null && jenisList.isNotEmpty) {
        selectedJenisPlastik = jenisList.firstWhere(
              (e) => e.idJenisPlastik == preselectId,
          orElse: () => jenisList.first,
        );
      } else if (jenisList.isNotEmpty) {
        // optional auto-select pertama
        // selectedJenisPlastik = jenisList.first;
      }
    } catch (e) {
      jenisError = e.toString();
      jenisList = [];
      selectedJenisPlastik = null;
    } finally {
      isJenisLoading = false;
      notifyListeners();
    }
  }

  // === FETCH HEADER (RESET) ===
  Future<void> fetchWashingHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    // ⬅️ reset selection saat daftar di-refresh supaya warna kembali default
    selectedNoWashing = null;
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = result['items'] as List<WashingHeader>;
      _totalPages = result['totalPages'] ?? 1;

      debugPrint("✅ Page $_page loaded, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error fetchWashingHeaders: $errorMessage");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // === LOAD MORE (PAGINATION) ===
  Future<void> loadMore() async {
    if (isFetchingMore || _page >= _totalPages) return;

    isFetchingMore = true;
    notifyListeners();

    try {
      _page++;
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      final moreItems = result['items'] as List<WashingHeader>;
      items.addAll(moreItems);

      debugPrint("📥 Load more page $_page, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error loadMore: $errorMessage");
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  bool get hasMore => _page < _totalPages;


  // === FETCH DETAIL ===
  Future<void> fetchDetails(String noWashing) async {
    // ⬅️ pastikan highlight pindah ke item yang dimuat detailnya
    setSelectedNoWashing(noWashing);

    details = [];
    detailError = '';
    isDetailLoading = true;
    notifyListeners();

    try {
      details = await repository.fetchDetails(noWashing);
      debugPrint("✅ Details loaded for $noWashing, count: ${details.length}");
    } catch (e) {
      detailError = e.toString();
      debugPrint("❌ Error fetchDetails($noWashing): $detailError");
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createWashing(
      WashingHeader header,
      List<WashingDetail> details,
      ) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.createWashing(header: header, details: details);

      lastCreatedNoWashing = res['data']?['header']?['NoWashing'] as String?;

      // refresh list
      await fetchWashingHeaders(search: _search);

      // ⬅️ opsional: auto-highlight hasil create
      if (lastCreatedNoWashing != null) {
        setSelectedNoWashing(lastCreatedNoWashing);
      }
      return res;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error createWashing: $errorMessage");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>?> updateWashing(
      String noWashing,
      WashingHeader header,
      List<WashingDetail> details,
      ) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.updateWashing(
        noWashing: noWashing,
        header: header,
        details: details,
      );

      // Refresh list agar data terbaru tampil
      await fetchWashingHeaders(search: _search);

      // Auto highlight yang barusan diupdate
      setSelectedNoWashing(noWashing);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error updateWashing: $errorMessage");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> deleteWashing(String noWashing) async {
    try {
      isLoading = true;
      notifyListeners();

      await repository.deleteWashing(noWashing);

      await fetchWashingHeaders(search: _search);

      // ⬇️ pastikan detail dibersihkan setelah delete
      details = [];
      detailError = '';
      selectedNoWashing = null;
      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error deleteWashing: $errorMessage");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  void resetForScreen() {
    // panggil ini saat masuk/keluar screen
    selectedNoWashing = null;
    details = [];
    detailError = '';
    // items tetap dibiarkan; akan diisi fetchWashingHeaders
  }
}
