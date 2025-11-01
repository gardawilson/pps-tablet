// lib/features/shared/inject_production/view_model/inject_production_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/inject_production_model.dart';
import '../repository/inject_production_repository.dart';

class InjectProductionViewModel extends ChangeNotifier {
  final InjectProductionRepository repository;
  InjectProductionViewModel({required this.repository});

  List<InjectProduction> items = [];
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
