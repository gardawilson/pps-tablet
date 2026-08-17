import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/network/api_error.dart';
import '../model/retur_v3_header.dart';
import '../repository/retur_v3_repository.dart';

class ReturV3ListViewModel extends ChangeNotifier {
  final ReturV3Repository repository;

  ReturV3ListViewModel({ReturV3Repository? repository})
    : repository = repository ?? ReturV3Repository() {
    _initPaging();
  }

  late final PagingController<int, ReturV3Header> _pagingController;
  PagingController<int, ReturV3Header> get pagingController =>
      _pagingController;

  String _search = '';
  String? _status;
  String? get status => _status;

  DateTime? _dateFrom;
  DateTime? _dateTo;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  String? deleteError;

  void _initPaging() {
    _pagingController = PagingController<int, ReturV3Header>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<ReturV3Header>> _fetchPage(int pageKey) async {
    final res = await repository.fetchAll(
      page: pageKey,
      pageSize: 20,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
      status: _status,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    final items = res['items'] as List<ReturV3Header>;
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
      _status != null || (_dateFrom != null && _dateTo != null);

  /// Terapkan status + rentang tanggal sekaligus (dipakai dialog filter
  /// gabungan) — cuma refresh paging sekali, bukan dua kali seperti kalau
  /// setStatus/setDateRange dipanggil terpisah.
  void applyFilters({String? status, DateTime? dateFrom, DateTime? dateTo}) {
    _status = status;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _pagingController.refresh();
    notifyListeners();
  }

  Future<bool> delete(String noRetur) async {
    deleteError = null;
    try {
      await repository.delete(noRetur);
      _pagingController.refresh();
      return true;
    } catch (e) {
      deleteError = apiErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  void refresh() => _pagingController.refresh();

  @override
  void dispose() {
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }
}
