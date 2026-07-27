import 'package:flutter/foundation.dart';

import '../model/retur_v2_pending_import.dart';
import '../repository/retur_v2_repository.dart';

class ReturV2PendingViewModel extends ChangeNotifier {
  final ReturV2Repository repository;

  ReturV2PendingViewModel({ReturV2Repository? repository})
    : repository = repository ?? ReturV2Repository();

  DateTime _date = DateTime.now();
  DateTime get date => _date;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<ReturV2PendingImport> _items = const [];
  List<ReturV2PendingImport> get items => _items;

  bool _hasFetched = false;
  bool get hasFetched => _hasFetched;

  Future<void> setDateAndFetch(DateTime date) async {
    _date = date;
    await fetch();
  }

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await repository.fetchPendingImport(_date);
    } catch (e) {
      _error = e.toString();
      _items = const [];
    } finally {
      _hasFetched = true;
      _loading = false;
      notifyListeners();
    }
  }
}
