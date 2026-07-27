import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/retur_v2_transaction.dart';
import '../repository/retur_v2_repository.dart';

class ReturV2ListViewModel extends ChangeNotifier {
  final ReturV2Repository repository;

  ReturV2ListViewModel({ReturV2Repository? repository})
    : repository = repository ?? ReturV2Repository() {
    _initPaging();
  }

  late final PagingController<int, ReturV2Transaction> _pagingController;
  PagingController<int, ReturV2Transaction> get pagingController =>
      _pagingController;

  String _search = '';

  void _initPaging() {
    _pagingController = PagingController<int, ReturV2Transaction>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<ReturV2Transaction>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
    );
    final items = res['items'] as List<ReturV2Transaction>;
    final totalPages = (res['totalPages'] as int?) ?? 1;
    if (pageKey > totalPages) return [];
    return items;
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

  void refresh() => _pagingController.refresh();

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
