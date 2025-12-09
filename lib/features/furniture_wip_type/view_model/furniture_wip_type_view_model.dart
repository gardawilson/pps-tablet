// lib/features/furniture_wip_type/view_model/packing_type_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/furniture_wip_type_model.dart';
import '../repository/furniture_wip_type_repository.dart';

class FurnitureWipTypeViewModel extends ChangeNotifier {
  final FurnitureWipTypeRepository repository;

  FurnitureWipTypeViewModel({required this.repository});

  List<FurnitureWipType> list = [];
  bool isLoading = false;
  String error = '';
  FurnitureWipType? selected;

  /// Load once (lazy), misalnya dari initState dropdown/screen
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

      // Deduplicate by idCabinetWip just in case
      final byId = <int, FurnitureWipType>{};
      for (final e in raw) {
        byId[e.idCabinetWip] = e;
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
      selected = list.firstWhere((e) => e.idCabinetWip == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
