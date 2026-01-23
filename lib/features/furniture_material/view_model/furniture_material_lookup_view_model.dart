// lib/features/furniture_material/view_model/furniture_material_lookup_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/furniture_material_lookup_model.dart';
import '../repository/furniture_material_lookup_repository.dart';

class FurnitureMaterialLookupViewModel extends ChangeNotifier {
  final FurnitureMaterialLookupRepository repository;
  FurnitureMaterialLookupViewModel({required this.repository});

  bool isLoading = false;
  String error = '';
  bool isEmpty = false;

  List<FurnitureMaterialLookupResult> items = [];

  int? _lastCetakan;
  int? _lastWarna;

  Future<void> resolve({
    required int idCetakan,
    required int idWarna,
  }) async {
    if (_lastCetakan == idCetakan &&
        _lastWarna == idWarna &&
        (items.isNotEmpty || error.isNotEmpty || isEmpty)) {
      return;
    }

    _lastCetakan = idCetakan;
    _lastWarna = idWarna;

    isLoading = true;
    error = '';
    isEmpty = false;
    items = [];
    notifyListeners();

    try {
      final list = await repository.fetchByCetakanWarna(
        idCetakan: idCetakan,
        idWarna: idWarna,
      );

      items = list;
      isEmpty = list.isEmpty;
    } catch (e) {
      error = e.toString();
      items = [];
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
    items = [];
    _lastCetakan = null;
    _lastWarna = null;
    notifyListeners();
  }
}
