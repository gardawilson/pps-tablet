// lib/features/furniture_material/view_model/furniture_material_lookup_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/furniture_material_lookup_model.dart';
import '../repository/furniture_material_lookup_repository.dart';

class FurnitureMaterialLookupViewModel extends ChangeNotifier {
  final FurnitureMaterialLookupRepository repository;
  FurnitureMaterialLookupViewModel({required this.repository});

  bool isLoading = false;

  /// error hanya untuk error beneran (exception / server / network)
  String error = '';

  /// ✅ true kalau mapping/data memang tidak ada (bukan error)
  bool isEmpty = false;

  FurnitureMaterialLookupResult? result;

  int? _lastCetakan;
  int? _lastWarna;

  Future<void> resolve({
    required int idCetakan,
    required int idWarna,
  }) async {
    // avoid duplicate (kalau sudah pernah resolve untuk kombinasi sama)
    if (_lastCetakan == idCetakan &&
        _lastWarna == idWarna &&
        (result != null || error.isNotEmpty || isEmpty)) {
      return;
    }

    _lastCetakan = idCetakan;
    _lastWarna = idWarna;

    isLoading = true;
    error = '';
    isEmpty = false;
    result = null;
    notifyListeners();

    try {
      final r = await repository.fetchByCetakanWarna(
        idCetakan: idCetakan,
        idWarna: idWarna,
      );

      if (r == null) {
        // ✅ ini bukan error, hanya tidak ada data
        isEmpty = true;
        result = null;
      } else {
        result = r;
        isEmpty = false;
      }
    } catch (e) {
      // ✅ ini baru error (merah)
      error = e.toString();
      result = null;
      isEmpty = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    isLoading = false;
    error = '';
    isEmpty = false;
    result = null;
    _lastCetakan = null;
    _lastWarna = null;
    notifyListeners();
  }
}
