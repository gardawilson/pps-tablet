import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/retur_v2_pending_import.dart';
import '../repository/retur_v2_repository.dart';

class ReturV2PendingViewModel extends ChangeNotifier {
  final ReturV2Repository repository;

  ReturV2PendingViewModel({ReturV2Repository? repository})
    : repository = repository ?? ReturV2Repository() {
    _initPaging();
  }

  late final PagingController<int, ReturV2PendingImportGroup> _pagingController;
  PagingController<int, ReturV2PendingImportGroup> get pagingController =>
      _pagingController;

  int _totalItems = 0;
  int get totalItems => _totalItems;

  void _initPaging() {
    _pagingController = PagingController<int, ReturV2PendingImportGroup>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<ReturV2PendingImportGroup>> _fetchPage(int pageKey) async {
    final res = await repository.fetchPendingImport(page: pageKey, pageSize: 20);
    final items = res['items'] as List<ReturV2PendingImportGroup>;
    final totalPages = (res['totalPages'] as int?) ?? 1;
    _totalItems = (res['total'] as int?) ?? 0;
    if (pageKey == 1) {
      // notify listeners outside the paging controller's own build phase
      Future.microtask(notifyListeners);
    }
    if (pageKey > totalPages) return [];
    return items;
  }

  void refresh() => _pagingController.refresh();

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
