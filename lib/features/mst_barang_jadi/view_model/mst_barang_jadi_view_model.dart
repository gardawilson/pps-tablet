import 'package:flutter/foundation.dart';

import '../model/mst_barang_jadi_model.dart';
import '../repository/mst_barang_jadi_repository.dart';

class MstBarangJadiViewModel extends ChangeNotifier {
  final MstBarangJadiRepository repository;

  MstBarangJadiViewModel({MstBarangJadiRepository? repository})
    : repository = repository ?? MstBarangJadiRepository();

  List<MstBarangJadi> items = [];
  bool isLoading = false;
  String error = '';
  bool _loaded = false;

  Future<void> refresh() => loadAll(forceReload: true);

  Future<void> loadAll({String search = '', bool forceReload = false}) async {
    if (_loaded && search.isEmpty && !forceReload) return;
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      items = await repository.fetchAll(search: search);
      if (search.isEmpty) _loaded = true;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
