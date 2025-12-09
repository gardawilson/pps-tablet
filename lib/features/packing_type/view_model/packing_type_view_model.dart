import 'package:flutter/foundation.dart';

import '../model/packing_type_model.dart';
import '../repository/packing_type_repository.dart';

class PackingTypeViewModel extends ChangeNotifier {
  final PackingTypeRepository repository;

  PackingTypeViewModel({required this.repository});

  List<PackingType> list = [];
  bool isLoading = false;
  String error = '';
  PackingType? selected;

  /// Load sekali (lazy), panggil dari initState dropdown/screen
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

      // Deduplicate by idBj just in case
      final byId = <int, PackingType>{};
      for (final e in raw) {
        byId[e.idBj] = e;
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
      selected = list.firstWhere((e) => e.idBj == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }

  /// (opsional) helper select by ItemCode kalau nanti perlu
  void selectByItemCode(String? code) {
    if (code == null || code.trim().isEmpty || list.isEmpty) {
      selected = null;
      notifyListeners();
      return;
    }
    try {
      selected = list.firstWhere(
            (e) => (e.itemCode ?? '').toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
