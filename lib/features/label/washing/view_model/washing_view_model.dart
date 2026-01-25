// lib/features/label/washing/view_model/washing_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';
import '../repository/washing_repository.dart';

import '../../../shared/plastic_type/jenis_plastik_model.dart';
import '../../../shared/plastic_type/jenis_plastik_repository.dart';

class WashingViewModel extends ChangeNotifier {
  WashingViewModel({required this.repository});

  // =============================
  // Dependencies
  // =============================
  final WashingRepository repository;
  final JenisPlastikRepository jenisRepo = JenisPlastikRepository();

  // =============================
  // Header list state
  // =============================
  List<WashingHeader> items = [];
  bool isLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _search = '';

  int get totalCount => _total;
  bool get hasMore => _page < _totalPages;

  // =============================
  // Selection + detail state
  // =============================
  String? selectedNoWashing; // single source of truth highlight
  List<WashingDetail> details = [];
  bool isDetailLoading = false;
  String detailError = '';

  // =============================
  // Jenis plastik state
  // =============================
  List<JenisPlastik> jenisList = [];
  JenisPlastik? selectedJenisPlastik;
  bool isJenisLoading = false;
  String jenisError = '';

  // =============================
  // Create result
  // =============================
  String? lastCreatedNoWashing;

  // =============================
  // Highlight helpers
  // =============================
  void setSelectedNoWashing(String? no) {
    if (selectedNoWashing == no) return;
    selectedNoWashing = no;
    notifyListeners();
  }

  // =============================
  // Jenis Plastik
  // =============================
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
      }
    } catch (e, st) {
      jenisError = e.toString();
      jenisList = [];
      selectedJenisPlastik = null;
      debugPrint('❌ loadJenisPlastik error: $e');
      debugPrint('$st');
    } finally {
      isJenisLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Fetch headers (reset)
  // =============================
  Future<void> fetchWashingHeaders({String search = ''}) async {
    _page = 1;
    _search = search;

    items = [];
    errorMessage = '';
    isLoading = true;

    // reset selection & detail
    selectedNoWashing = null;
    details = [];
    detailError = '';
    isDetailLoading = false;

    notifyListeners();

    try {
      final result = await repository.fetchHeaders(
        page: _page,
        limit: 20,
        search: _search,
      );

      items = (result['items'] as List<WashingHeader>);
      _totalPages = (result['totalPages'] ?? 1) as int;
      _total = (result['total'] ?? items.length) as int;

      debugPrint('✅ fetchWashingHeaders page=$_page items=${items.length} total=$_total');
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('❌ fetchWashingHeaders error: $e');
      debugPrint('$st');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Load more (pagination)
  // =============================
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

      final moreItems = (result['items'] as List<WashingHeader>);
      items.addAll(moreItems);

      debugPrint('📥 loadMore page=$_page add=${moreItems.length} totalNow=${items.length}');
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('❌ loadMore error: $e');
      debugPrint('$st');
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  // =============================
  // Fetch details
  // =============================
  Future<void> fetchDetails(String noWashing) async {
    setSelectedNoWashing(noWashing);

    details = [];
    detailError = '';
    isDetailLoading = true;
    notifyListeners();

    try {
      details = await repository.fetchDetails(noWashing);
      debugPrint('✅ fetchDetails $noWashing count=${details.length}');
    } catch (e, st) {
      detailError = e.toString();
      debugPrint('❌ fetchDetails($noWashing) error: $e');
      debugPrint('$st');
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Create
  // =============================
  Future<Map<String, dynamic>?> createWashing(
      WashingHeader header,
      List<WashingDetail> detailsData,
      ) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.createWashing(header: header, details: detailsData);

      lastCreatedNoWashing = res['data']?['header']?['NoWashing'] as String?;

      // refresh list
      await fetchWashingHeaders(search: _search);

      // optional: auto highlight created
      if (lastCreatedNoWashing != null) {
        setSelectedNoWashing(lastCreatedNoWashing);
      }

      return res;
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('❌ createWashing error: $e');
      debugPrint('$st');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Update
  // =============================
  Future<Map<String, dynamic>?> updateWashing(
      String noWashing,
      WashingHeader header,
      List<WashingDetail> detailsData,
      ) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      final res = await repository.updateWashing(
        noWashing: noWashing,
        header: header,
        details: detailsData,
      );

      // refresh list
      await fetchWashingHeaders(search: _search);

      // keep highlight
      setSelectedNoWashing(noWashing);

      return res;
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('❌ updateWashing error: $e');
      debugPrint('$st');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Delete
  // =============================
  Future<bool> deleteWashing(String noWashing) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      await repository.deleteWashing(noWashing);

      await fetchWashingHeaders(search: _search);

      // clear detail & selection
      details = [];
      detailError = '';
      selectedNoWashing = null;

      notifyListeners();
      return true;
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('❌ deleteWashing error: $e');
      debugPrint('$st');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // Reset screen state
  // =============================
  void resetForScreen() {
    selectedNoWashing = null;

    details = [];
    detailError = '';
    isDetailLoading = false;

    errorMessage = '';
    notifyListeners();
  }
}
