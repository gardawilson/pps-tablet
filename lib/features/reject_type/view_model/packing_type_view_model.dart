// lib/features/reject_type/view_model/reject_type_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/reject_type_model.dart';
import '../repository/reject_type_repository.dart';

class RejectTypeViewModel extends ChangeNotifier {
  final RejectTypeRepository repository;

  RejectTypeViewModel({required this.repository});

  List<RejectType> list = [];
  bool isLoading = false;
  String error = '';
  RejectType? selected;

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

      // Deduplicate by idReject just in case
      final byId = <int, RejectType>{};
      for (final e in raw) {
        byId[e.idReject] = e;
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
      selected = list.firstWhere((e) => e.idReject == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }

  /// (opsional) helper select by ItemCode
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
