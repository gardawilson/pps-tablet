import 'package:flutter/material.dart';
import '../model/broker_header_model.dart';
import '../model/broker_detail_model.dart';
import '../model/broker_partial_model.dart';
import '../repository/broker_repository.dart';
import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../shared/plastic_type/jenis_plastik_repository.dart';

class BrokerViewModel extends ChangeNotifier {
  final BrokerRepository repository;

  BrokerViewModel({required this.repository});

  // === HEADER STATE ===
  List<BrokerHeader> items = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _search = '';

  /// Public getter for total rows from the API
  int get totalCount => _total;

  // === DETAIL STATE ===
  String? selectedNoBroker; // ⬅️ satu-satunya sumber highlight
  List<BrokerDetail> details = [];
  bool isDetailLoading = false;
  String detailError = '';

  // === JENIS PLASTIK STATE ===
  final JenisPlastikRepository jenisRepo = JenisPlastikRepository();
  List<JenisPlastik> jenisList = [];
  JenisPlastik? selectedJenisPlastik;
  bool isJenisLoading = false;
  String jenisError = '';

  String? lastCreatedNoBroker;

  // === PARTIAL INFO STATE ===
  BrokerPartialInfo? partialInfo;
  bool isPartialLoading = false;
  String? partialError;

  // Helper: current selected broker code (you already store it)
  String? get currentNoBroker => selectedNoBroker;

  // =============================
  //  Highlight helpers
  // =============================

  /// Set / pindahkan highlight ke [no] (atau null untuk clear) tanpa memuat detail.
  void setSelectedNoBroker(String? no) { // ⬅️ baru
    if (selectedNoBroker == no) return;
    selectedNoBroker = no;
    notifyListeners();
  }

  // BrokerViewModel
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
  Future<void> fetchBrokerHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    // ⬅️ reset selection saat daftar di-refresh supaya warna kembali default
    selectedNoBroker = null;
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = result['items'] as List<BrokerHeader>;
      _totalPages = result['totalPages'] ?? 1;
      _total = result['total'] ?? 0;


      debugPrint("✅ Page $_page loaded, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error fetchBrokerHeaders: $errorMessage");
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

      final moreItems = result['items'] as List<BrokerHeader>;
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
  Future<void> fetchDetails(String noBroker) async {
    // ⬅️ pastikan highlight pindah ke item yang dimuat detailnya
    setSelectedNoBroker(noBroker);

    details = [];
    detailError = '';
    isDetailLoading = true;
    notifyListeners();

    try {
      details = await repository.fetchDetails(noBroker);
      debugPrint("✅ Details loaded for $noBroker, count: ${details.length}");
    } catch (e) {
      detailError = e.toString();
      debugPrint("❌ Error fetchDetails($noBroker): $detailError");
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createBroker(
      BrokerHeader header,
      List<BrokerDetail> details,
      ) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.createBroker(header: header, details: details);

      lastCreatedNoBroker = res['data']?['header']?['NoBroker'] as String?;

      // refresh list
      await fetchBrokerHeaders(search: _search);

      // ⬅️ opsional: auto-highlight hasil create
      if (lastCreatedNoBroker != null) {
        setSelectedNoBroker(lastCreatedNoBroker);
      }
      return res;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error createBroker: $errorMessage");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<Map<String, dynamic>?> updateBroker(
      String noBroker,
      BrokerHeader header,
      List<BrokerDetail> details,
      ) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await repository.updateBroker(
        noBroker: noBroker,
        header: header,
        details: details,
      );

      // Refresh list agar data terbaru tampil
      await fetchBrokerHeaders(search: _search);

      // Auto highlight yang barusan diupdate
      setSelectedNoBroker(noBroker);

      return res;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error updateBroker: $errorMessage");
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> deleteWashing(String noBroker) async {
    try {
      isLoading = true;
      notifyListeners();

      await repository.deleteBroker(noBroker);

      await fetchBrokerHeaders(search: _search);

      // ⬇️ pastikan detail dibersihkan setelah delete
      details = [];
      detailError = '';
      selectedNoBroker = null;
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

  Future<void> loadPartialInfo({required int noSak}) async {
    final nb = currentNoBroker;
    if (nb == null || nb.isEmpty) {
      partialError = "NoBroker not selected";
      partialInfo = null;
      notifyListeners();
      return;
    }

    try {
      isPartialLoading = true;
      partialError = null;
      notifyListeners();

      partialInfo = await repository.fetchPartialInfo(noBroker: nb, noSak: noSak);
    } catch (e) {
      partialError = e.toString();
      partialInfo = null;
    } finally {
      isPartialLoading = false;
      notifyListeners();
    }
  }


  void resetForScreen() {
    // panggil ini saat masuk/keluar screen
    selectedNoBroker = null;
    details = [];
    detailError = '';
    // items tetap dibiarkan; akan diisi fetchBrokerHeaders
  }

}
