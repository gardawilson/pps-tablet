import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/so_v2_label_group.dart';
import '../model/so_v2_label_row.dart';
import '../repository/so_v2_repository.dart';

class SoV2LabelListViewModel extends ChangeNotifier {
  final String stockOpnameNo;
  final String blok;
  final int locationId;
  final String categoryCode;
  final SoV2Repository repository;

  SoV2LabelListViewModel({
    required this.stockOpnameNo,
    required this.blok,
    required this.locationId,
    required this.categoryCode,
    SoV2Repository? repository,
  }) : repository = repository ?? SoV2Repository() {
    _initPaging();
  }

  late final PagingController<int, SoV2LabelGroup> _pagingController;
  PagingController<int, SoV2LabelGroup> get pagingController =>
      _pagingController;

  String _search = '';

  bool isComplete = false;
  double totalWeight = 0;
  int totalRecords = 0;
  int totalScanned = 0;

  void _initPaging() {
    _pagingController = PagingController<int, SoV2LabelGroup>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<SoV2LabelGroup>> _fetchPage(int pageKey) async {
    final page = await repository.fetchLabelPage(
      stockOpnameNo: stockOpnameNo,
      blok: blok,
      locationId: locationId,
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
    );
    isComplete = page.isComplete;
    totalWeight = page.totalWeight;
    totalRecords = page.totalRecords;
    totalScanned = page.totalScanned;
    notifyListeners();
    if (pageKey > page.totalPages) return [];
    return page.data;
  }

  /// Update optimistik lokal setelah event realtime `stock_opname_hasil_inserted`
  /// — patch checklist baris label yang sudah termuat di halaman saat ini
  /// tanpa memicu refetch/loading indicator. `totalScanned` selalu
  /// di-update (server sudah konfirmasi insert-nya) walau barisnya belum
  /// termuat di halaman yang sedang dibuka (mis. masih di halaman
  /// berikutnya / sedang difilter search). `totalWeight` tidak ikut
  /// di-update — itu total berat SELURUH label lokasi (target), bukan
  /// akumulasi berat yang sudah discan.
  void applyScan({
    required String labelNo,
    bool isLocationMismatch = false,
    String? scannedBlok,
    int? scannedLocationId,
  }) {
    _patchRow(
      labelNo,
      (row) => row.markScanned(
        isLocationMismatch: isLocationMismatch,
        scannedBlok: scannedBlok,
        scannedLocationId: scannedLocationId,
      ),
      matchScanned: false,
    );
    totalScanned += 1;
    notifyListeners();
  }

  /// Kebalikan dari [applyScan], dipanggil setelah hasil scan dihapus (baik
  /// oleh device sendiri lewat [SoV2Repository.deleteHasilLabel], maupun
  /// dari device lain lewat event realtime `stock_opname_hasil_deleted`).
  /// Return true kalau barisnya termuat di halaman saat ini (state
  /// tercentang berhasil di-patch); caller tidak perlu fallback reload
  /// kalau false — cukup biarkan stale sampai user refresh manual, karena
  /// event ini jarang terjadi.
  bool applyUnscan(String labelNo) {
    final patched = _patchRow(
      labelNo,
      (row) => row.unmarkScanned(),
      matchScanned: true,
    );
    if (patched) {
      totalScanned = (totalScanned - 1).clamp(0, totalRecords);
      notifyListeners();
    }
    return patched;
  }

  bool _patchRow(
    String labelNo,
    SoV2LabelRow Function(SoV2LabelRow row) transform, {
    required bool matchScanned,
  }) {
    final state = _pagingController.value;
    final pages = state.pages;
    if (pages == null) return false;

    var patched = false;
    final newPages = <List<SoV2LabelGroup>>[];
    for (final page in pages) {
      final newPage = <SoV2LabelGroup>[];
      for (final group in page) {
        final idx = group.labels.indexWhere(
          (l) => l.primaryValue == labelNo && l.isScanned == matchScanned,
        );
        if (idx == -1) {
          newPage.add(group);
          continue;
        }
        final newLabels = List<SoV2LabelRow>.from(group.labels);
        newLabels[idx] = transform(newLabels[idx]);
        newPage.add(group.copyWithLabels(newLabels));
        patched = true;
      }
      newPages.add(newPage);
    }
    if (patched) {
      _pagingController.value = state.copyWith(pages: newPages);
    }
    return patched;
  }

  Timer? _debounce;
  void setSearchDebounced(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search = text;
      _pagingController.refresh();
    });
  }

  void clearSearch() {
    _search = '';
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
