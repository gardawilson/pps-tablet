import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/network/api_error.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';

class BsV2ListViewModel extends ChangeNotifier {
  final BsV2Repository repository;

  BsV2ListViewModel({BsV2Repository? repository})
      : repository = repository ?? BsV2Repository() {
    _initPaging();
  }

  late final PagingController<int, BsV2Transaction> _pagingController;
  PagingController<int, BsV2Transaction> get pagingController => _pagingController;

  String _search = '';
  bool isSaving = false;
  String? saveError;

  void _initPaging() {
    _pagingController = PagingController<int, BsV2Transaction>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<BsV2Transaction>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
    );
    final items = res['items'] as List<BsV2Transaction>;
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

  Future<bool> delete(String noBongkarSusun) async {
    saveError = null;
    try {
      await repository.delete(noBongkarSusun);
      _pagingController.refresh();
      return true;
    } catch (e) {
      saveError = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
