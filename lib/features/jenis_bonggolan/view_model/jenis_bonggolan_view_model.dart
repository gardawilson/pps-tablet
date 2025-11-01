// lib/features/shared/bonggolan_type/jenis_bonggolan_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/jenis_bonggolan_model.dart';
import '../repository/jenis_bonggolan_repository.dart';


class JenisBonggolanViewModel extends ChangeNotifier {
  final JenisBonggolanRepository repository;
  JenisBonggolanViewModel({required this.repository});

  List<JenisBonggolan> list = [];
  bool isLoading = false;
  String error = '';
  JenisBonggolan? selected;

  Future<void> ensureLoaded() async {
    if (list.isNotEmpty || isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    isLoading = true; error = ''; notifyListeners();
    try {
      final raw = await repository.fetchAllActive();
      // dedupe by id
      final byId = <int, JenisBonggolan>{};
      for (final e in raw) {
        byId[e.idBonggolan] = e;
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
      selected = list.firstWhere((e) => e.idBonggolan == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
