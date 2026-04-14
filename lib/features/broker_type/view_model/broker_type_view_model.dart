import 'package:flutter/foundation.dart';

import '../model/broker_type_model.dart';
import '../repository/broker_type_repository.dart';

class BrokerTypeViewModel extends ChangeNotifier {
  final BrokerTypeRepository repository;

  BrokerTypeViewModel({required this.repository});

  List<BrokerType> list = [];
  bool isLoading = false;
  String error = '';
  BrokerType? selected;

  Future<void> ensureLoaded() async {
    if (list.isNotEmpty || isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      final raw = await repository.fetchAllActive();
      final byId = <int, BrokerType>{};
      for (final e in raw) {
        byId[e.idBroker] = e;
      }
      list = byId.values.toList();
    } catch (e) {
      error = e.toString();
      list = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectById(int? id) {
    if (id == null || list.isEmpty) {
      selected = null;
      notifyListeners();
      return;
    }

    try {
      selected = list.firstWhere((e) => e.idBroker == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
