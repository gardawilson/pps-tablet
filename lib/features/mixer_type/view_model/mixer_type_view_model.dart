import 'package:flutter/foundation.dart';

import '../model/mixer_type_model.dart';
import '../repository/mixer_type_repository.dart';

class MixerTypeViewModel extends ChangeNotifier {
  final MixerTypeRepository repository;
  MixerTypeViewModel({required this.repository});

  List<MixerType> list = [];
  bool isLoading = false;
  String error = '';
  MixerType? selected;

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
      // dedupe by id
      final byId = <int, MixerType>{};
      for (final e in raw) {
        byId[e.idMixer] = e;
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
      selected = list.firstWhere((e) => e.idMixer == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
