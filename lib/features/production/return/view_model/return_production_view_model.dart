// lib/features/shared/return_production/packing_production_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/return_production_model.dart';
import '../repository/return_production_repository.dart';

class ReturnProductionViewModel extends ChangeNotifier {
  final ReturnProductionRepository repository;

  ReturnProductionViewModel({required this.repository});

  List<ReturnProduction> items = [];
  bool isLoading = false;
  String error = '';

  /// Load BJRetur_h for a specific date
  /// Backend: GET /api/returns/:date (YYYY-MM-DD)
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
