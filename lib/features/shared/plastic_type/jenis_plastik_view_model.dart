import 'package:flutter/foundation.dart';
import 'jenis_plastik_model.dart';
import 'jenis_plastik_repository.dart';

class JenisPlastikViewModel extends ChangeNotifier {
  final JenisPlastikRepository repository;
  JenisPlastikViewModel({required this.repository});

  List<JenisPlastik> list = [];
  bool isLoading = false;
  String error = '';
  JenisPlastik? selected; // opsional, kalau mau share state global

  /// Hanya fetch kalau belum ada data (cache)
  Future<void> ensureLoaded({bool onlyActive = true}) async {
    if (list.isNotEmpty || isLoading) return;
    await refresh(onlyActive: onlyActive);
  }

  /// Force fetch dari server
  Future<void> refresh({bool onlyActive = true}) async {
    isLoading = true; error = ''; notifyListeners();
    try {
      final raw = await repository.fetchAll(onlyActive: onlyActive);

      // dedupe by id jika perlu
      final byId = <int, JenisPlastik>{};
      for (final e in raw) {
        byId[e.idJenisPlastik] = e;
      }
      list = byId.values.toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  /// Set pilihan berdasar ID (biasanya untuk preselect)
  void selectById(int? id) {
    if (id == null || list.isEmpty) {
      selected = null;
      notifyListeners();
      return;
    }
    try {
      selected = list.firstWhere((e) => e.idJenisPlastik == id);
    } catch (_) {
      selected = null;
    }
    notifyListeners();
  }
}
