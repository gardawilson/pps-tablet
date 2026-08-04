import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/network/api_error.dart';
import '../model/trade_in_transaction.dart';
import '../repository/trade_in_repository.dart';

class TradeInListViewModel extends ChangeNotifier {
  final TradeInRepository repository;

  TradeInListViewModel({TradeInRepository? repository})
    : repository = repository ?? TradeInRepository() {
    _initPaging();
  }

  late final PagingController<int, TradeInTransaction> _pagingController;
  PagingController<int, TradeInTransaction> get pagingController =>
      _pagingController;

  String _search = '';

  void _initPaging() {
    _pagingController = PagingController<int, TradeInTransaction>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<TradeInTransaction>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      filter: _search.trim().isNotEmpty ? _search.trim() : null,
    );
    final items = res['items'] as List<TradeInTransaction>;
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

  /// Return null on success, or an error message string.
  Future<String?> deleteItem(String noPenerimaan) async {
    try {
      await repository.delete(noPenerimaan);
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
