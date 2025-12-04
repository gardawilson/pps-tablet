import 'package:flutter/foundation.dart';

import '../model/spanner_production_model.dart';
import '../repository/spanner_production_repository.dart';


class SpannerProductionViewModel extends ChangeNotifier {
  final SpannerProductionRepository repository;

  SpannerProductionViewModel({required this.repository});

  List<SpannerProduction> items = [];
  bool isLoading = false;
  String error = '';

  /// Load Spanner_h for a specific date
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
