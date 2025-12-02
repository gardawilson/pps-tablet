import 'package:flutter/foundation.dart';

import '../model/gilingan_type_model.dart';
import '../repository/gilingan_type_repository.dart';

class GilinganTypeViewModel extends ChangeNotifier {
  final GilinganTypeRepository repository;
  GilinganTypeViewModel({required this.repository});

  List<GilinganType> list = [];
  bool isLoading = false;
  String error = '';
  GilinganType? selected;

  /// Load once (lazy), e.g. from initState of dropdown/screen
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

      // Deduplicate by idGilingan just in case
      final byId = <int, GilinganType>{};
      for (final e in raw) {
        byId[e.idGilingan] = e;
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
      selected = list.firstWhere((e) => e.idGilingan == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
