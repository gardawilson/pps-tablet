import 'package:flutter/material.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';
import '../repository/washing_repository.dart';

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
  String? selectedNoWashing;
  List<WashingDetail> details = [];
  bool isDetailLoading = false;
  String detailError = '';

  // === FETCH HEADER (RESET) ===
  Future<void> fetchWashingHeaders({String search = ''}) async {
    _page = 1;
    _search = search;
    items = [];
    errorMessage = '';
    notifyListeners();

    try {
      isLoading = true;
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = result['items'] as List<WashingHeader>;
      _totalPages = result['totalPages'] ?? 1;

      print("✅ Page $_page loaded, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      print("❌ Error fetchWashingHeaders: $errorMessage");
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

      print("📥 Load more page $_page, total items: ${items.length}");
    } catch (e) {
      errorMessage = e.toString();
      print("❌ Error loadMore: $errorMessage");
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  bool get hasMore => _page < _totalPages;

  // === FETCH DETAIL ===
  Future<void> fetchDetails(String noWashing) async {
    selectedNoWashing = noWashing;
    details = [];
    detailError = '';
    isDetailLoading = true;
    notifyListeners();

    try {
      details = await repository.fetchDetails(noWashing);
      print("✅ Details loaded for $noWashing, count: ${details.length}");
    } catch (e) {
      detailError = e.toString();
      print("❌ Error fetchDetails($noWashing): $detailError");
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }
}
