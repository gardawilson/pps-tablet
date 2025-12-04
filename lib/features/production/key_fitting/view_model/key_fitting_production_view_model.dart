// lib/features/shared/key_fitting_production/view_model/hot_stamp_production_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/key_fitting_production_model.dart';
import '../repository/key_fitting_production_repository.dart';

class KeyFittingProductionViewModel extends ChangeNotifier {
  final KeyFittingProductionRepository repository;

  KeyFittingProductionViewModel({required this.repository});

  List<KeyFittingProduction> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> fetchByDate(DateTime date) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchByDate(date);
    } catch (e) {
      error = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    items = [];
    error = '';
    isLoading = false;
    notifyListeners();
  }
}
