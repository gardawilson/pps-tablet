// lib/features/shared/gilingan_production/hot_stamp_production_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/gilingan_production_model.dart';
import '../repository/gilingan_production_repository.dart';

class GilinganProductionViewModel extends ChangeNotifier {
  final GilinganProductionRepository repository;

  GilinganProductionViewModel({required this.repository});

  List<GilinganProduction> items = [];
  bool isLoading = false;
  String error = '';

  /// Load GilinganProduksi_h for a specific date
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
