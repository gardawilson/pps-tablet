import 'package:flutter/foundation.dart';

import '../model/washing_type_model.dart';
import '../repository/washing_type_repository.dart';

class WashingTypeViewModel extends ChangeNotifier {
  final WashingTypeRepository repository;

  WashingTypeViewModel({required this.repository});

  List<WashingType> list = [];
  bool isLoading = false;
  String error = '';
  WashingType? selected;

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
      final byId = <int, WashingType>{};
      for (final e in raw) {
        byId[e.idWashing] = e;
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
      selected = list.firstWhere((e) => e.idWashing == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
