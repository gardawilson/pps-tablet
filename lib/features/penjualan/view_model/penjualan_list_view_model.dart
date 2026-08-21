import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../model/penjualan_header_model.dart';
import '../repository/penjualan_repository.dart';

class PenjualanListViewModel extends ChangeNotifier {
  final PenjualanRepository repository;

  PenjualanListViewModel({PenjualanRepository? repository})
    : repository = repository ?? PenjualanRepository() {
    _initPaging();
  }

  late final PagingController<int, PenjualanHeader> _pagingController;
  PagingController<int, PenjualanHeader> get pagingController =>
      _pagingController;

  String _search = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  // 'incomplete' (default) | 'complete' | 'all'
  String _status = 'incomplete';
  String get status => _status;

  void _initPaging() {
    _pagingController = PagingController<int, PenjualanHeader>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<PenjualanHeader>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      status: _status,
    );
    final items = res['items'] as List<PenjualanHeader>;
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

  bool get hasActiveFilter =>
      _status != 'incomplete' || (_dateFrom != null && _dateTo != null);

  /// Terapkan status + rentang tanggal sekaligus (dipakai dialog filter
  /// gabungan) — cuma refresh paging sekali.
  void applyFilters({String? status, DateTime? dateFrom, DateTime? dateTo}) {
    _status = status ?? 'incomplete';
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _pagingController.refresh();
    notifyListeners();
  }

  void refresh() => _pagingController.refresh();

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
