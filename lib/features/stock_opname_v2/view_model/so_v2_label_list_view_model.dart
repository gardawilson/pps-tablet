import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/network/api_error.dart';
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

  late final PagingController<int, SoV2LabelRow> _pagingController;
  PagingController<int, SoV2LabelRow> get pagingController =>
      _pagingController;

  String _search = '';

  bool isComplete = false;
  double totalWeight = 0;
  int totalRecords = 0;
  int totalScanned = 0;

  bool get palletNoRequired =>
      categoryCode == 'bahanbaku' || categoryCode == 'bahanbakupakai';

  void _initPaging() {
    _pagingController = PagingController<int, SoV2LabelRow>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<SoV2LabelRow>> _fetchPage(int pageKey) async {
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

  /// Return null on success, or an error message string.
  Future<String?> scanLabel({required String labelNo, int? palletNo}) async {
    try {
      await repository.submitHasil(
        stockOpnameNo: stockOpnameNo,
        labelNo: labelNo,
        palletNo: palletNo,
      );
      _pagingController.refresh();
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
