import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../model/stock_opname_model.dart';
import '../repository/stock_opname_repository.dart';

class StockOpnameViewModel extends ChangeNotifier {
  final StockOpnameRepository repository;

  StockOpnameViewModel({required this.repository}) {
    // Definisikan cara ambil page & cara hitung next key
    pagingController = PagingController<int, StockOpname>(
      getNextPageKey: (state) {
        if (!_hasMore || state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: _fetchPaged,
    );
  }

  late final PagingController<int, StockOpname> pagingController;

  String _activeFilter = 'Semua';
  String _searchQuery = '';
  String _errorMessage = '';
  int _totalResults = 0;
  bool _hasMore = true;
  static const int _pageSize = 10;

  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String get errorMessage => _errorMessage;
  int get totalResults => _totalResults;

  Future<List<StockOpname>> _fetchPaged(int pageKey) async {
    try {
      final result = await repository.fetchStockOpnamePaged(
        page: pageKey,
        limit: _pageSize,
        search: _searchQuery.trim(),
        filter: _activeFilter,
      );

      _totalResults = result.total;
      _errorMessage = '';
      final totalPages = (result.total / _pageSize).ceil();
      _hasMore = pageKey < totalPages && result.data.length >= _pageSize;

      notifyListeners();

      // Hentikan pagination bila pageKey sudah melampaui totalPages
      if (pageKey > totalPages) {
        return const <StockOpname>[];
      }

      return result.data;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void setFilter(String filter) {
    if (_activeFilter != filter) {
      _activeFilter = filter;
      _errorMessage = '';
      _hasMore = true;
      pagingController.refresh();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _errorMessage = '';
      _hasMore = true;
      pagingController.refresh();
      notifyListeners();
    }
  }

  void refresh() {
    _errorMessage = '';
    _hasMore = true;
    pagingController.refresh();
    notifyListeners();
  }

  void reset() {
    _activeFilter = 'Semua';
    _searchQuery = '';
    _errorMessage = '';
    _totalResults = 0;
    _hasMore = true;
    pagingController.refresh();
    notifyListeners();
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
  }
}
