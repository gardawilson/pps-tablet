import 'package:flutter/foundation.dart';

import '../model/crusher_type_model.dart';
import '../repository/crusher_type_repository.dart';

class CrusherTypeViewModel extends ChangeNotifier {
  final CrusherTypeRepository repository;
  CrusherTypeViewModel({required this.repository});

  List<CrusherType> list = [];
  bool isLoading = false;
  String error = '';
  CrusherType? selected;

  Future<void> ensureLoaded() async {
    if (list.isNotEmpty || isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    isLoading = true; error = ''; notifyListeners();
    try {
      final raw = await repository.fetchAllActive();
      // dedupe by id
      final byId = <int, CrusherType>{};
      for (final e in raw) {
        byId[e.idCrusher] = e;
      }
      list = byId.values.toList();
    } catch (e) {
      error = e.toString();
      list = [];
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  void selectById(int? id) {
    if (id == null || list.isEmpty) {
      selected = null;
      notifyListeners();
      return;
    }
    try {
      selected = list.firstWhere((e) => e.idCrusher == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
