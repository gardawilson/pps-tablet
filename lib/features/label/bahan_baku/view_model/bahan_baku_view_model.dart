// lib/features/production/bahan_baku/viewmodel/bahan_baku_viewmodel.dart
import 'package:flutter/material.dart';
import '../model/bahan_baku_header.dart';
import '../model/bahan_baku_pallet.dart';
import '../model/bahan_baku_pallet_detail.dart';
import '../repository/bahan_baku_repository.dart';

class BahanBakuViewModel extends ChangeNotifier {
  final BahanBakuRepository repository;

  BahanBakuViewModel({required this.repository});

  // === HEADER STATE ===
  List<BahanBakuHeader> items = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _search = '';

  /// Public getter for total rows from the API
  int get totalCount => _total;

  // === PALLET STATE ===
  String? selectedNoBahanBaku; // ⬅️ satu-satunya sumber highlight untuk header
  List<BahanBakuPallet> pallets = [];
  bool isPalletLoading = false;
  String palletError = '';

  // === DETAIL STATE (NoSak per pallet) ===
  String? selectedNoPallet; // ⬅️ satu-satunya sumber highlight untuk pallet
  List<BahanBakuPalletDetail> details = [];
  bool isDetailLoading = false;
  String detailError = '';

  // Helper: current selected codes
  String? get currentNoBahanBaku => selectedNoBahanBaku;
  String? get currentNoPallet => selectedNoPallet;

  // =============================
  //  Highlight helpers
  // =============================

  /// Set / pindahkan highlight ke [no] (atau null untuk clear) tanpa memuat pallet
  void setSelectedNoBahanBaku(String? no) {
    if (selectedNoBahanBaku == no) return;
    selectedNoBahanBaku = no;
    // Reset pallet & detail saat ganti header
    selectedNoPallet = null;
    pallets = [];
    details = [];
    notifyListeners();
  }

  /// Set / pindahkan highlight ke [no] (atau null untuk clear) tanpa memuat detail
  void setSelectedNoPallet(String? no) {
    if (selectedNoPallet == no) return;
    selectedNoPallet = no;
    // Reset detail saat ganti pallet
    details = [];
    notifyListeners();
  }

  // === FETCH HEADER (RESET) ===
  Future<void> fetchBahanBakuHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    isLoading = true;
    // ⬅️ reset selection saat daftar di-refresh
    selectedNoBahanBaku = null;
    selectedNoPallet = null;
    pallets = [];
    details = [];
    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = result['items'] as List<BahanBakuHeader>;
      _totalPages = result['totalPages'] ?? 1;
      _total = result['total'] ?? 0;

      debugPrint("✅ Page $_page loaded, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("❌ Error fetchBahanBakuHeaders: $errorMessage");
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

      final moreItems = result['items'] as List<BahanBakuHeader>;
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

  // === FETCH PALLETS ===
  Future<void> fetchPallets(String noBahanBaku) async {
    // ⬅️ pastikan highlight pindah ke item yang dimuat palletnya
    setSelectedNoBahanBaku(noBahanBaku);

    pallets = [];
    palletError = '';
    isPalletLoading = true;
    notifyListeners();

    try {
      pallets = await repository.fetchPallets(noBahanBaku);
      debugPrint("✅ Pallets loaded for $noBahanBaku, count: ${pallets.length}");
    } catch (e) {
      palletError = e.toString();
      debugPrint("❌ Error fetchPallets($noBahanBaku): $palletError");
    } finally {
      isPalletLoading = false;
      notifyListeners();
    }
  }

  // === FETCH DETAIL (NoSak per pallet) ===
  Future<void> fetchPalletDetails({
    required String noBahanBaku,
    required String noPallet,
  }) async {
    // ⬅️ pastikan highlight pindah ke pallet yang dimuat detailnya
    setSelectedNoPallet(noPallet);

    details = [];
    detailError = '';
    isDetailLoading = true;
    notifyListeners();

    try {
      details = await repository.fetchPalletDetails(
        noBahanBaku: noBahanBaku,
        noPallet: noPallet,
      );
      debugPrint("✅ Details loaded for $noBahanBaku/$noPallet, count: ${details.length}");
    } catch (e) {
      detailError = e.toString();
      debugPrint("❌ Error fetchPalletDetails($noBahanBaku/$noPallet): $detailError");
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Reset state saat masuk/keluar screen
  void resetForScreen() {
    selectedNoBahanBaku = null;
    selectedNoPallet = null;
    pallets = [];
    details = [];
    palletError = '';
    detailError = '';
    // items tetap dibiarkan; akan diisi fetchBahanBakuHeaders
  }
}