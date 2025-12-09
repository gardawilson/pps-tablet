import 'package:flutter/foundation.dart';

import '../model/packing_production_model.dart';
import '../repository/packing_production_repository.dart';

class PackingProductionViewModel extends ChangeNotifier {
  final PackingProductionRepository repository;

  PackingProductionViewModel({required this.repository});

  List<PackingProduction> items = [];
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
