import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/so_v2_label_group.dart';
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
