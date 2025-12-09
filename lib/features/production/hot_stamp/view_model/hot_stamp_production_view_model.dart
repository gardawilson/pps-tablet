// lib/features/shared/hot_stamp_production/packing_production_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/hot_stamp_production_model.dart';
import '../repository/hot_stamp_production_repository.dart';


class HotStampProductionViewModel extends ChangeNotifier {
  final HotStampProductionRepository repository;

  HotStampProductionViewModel({required this.repository});

  List<HotStampProduction> items = [];
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
