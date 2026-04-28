import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/sr_v2_transaction.dart';
import '../repository/sr_v2_repository.dart';

class SrV2ListViewModel extends ChangeNotifier {
  final SrV2Repository repository;

  SrV2ListViewModel({SrV2Repository? repository})
      : repository = repository ?? SrV2Repository() {
    _initPaging();
  }

  late final PagingController<int, SrV2Transaction> _pagingController;
  PagingController<int, SrV2Transaction> get pagingController =>
      _pagingController;

  String _search = '';

  void _initPaging() {
    _pagingController = PagingController<int, SrV2Transaction>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<SrV2Transaction>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
    );
    final items = res['items'] as List<SrV2Transaction>;
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
