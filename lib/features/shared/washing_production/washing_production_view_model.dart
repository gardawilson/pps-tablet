import 'package:flutter/foundation.dart';
import 'washing_production_repository.dart';
import 'washing_production_model.dart';

class WashingProductionViewModel extends ChangeNotifier {
  final WashingProductionRepository repository;
  WashingProductionViewModel({required this.repository});

  bool isLoading = false;
  String error = '';
  List<WashingProduction> items = [];


  // Opsional
  Future<void> fetchByDate(DateTime date) async {
    isLoading = true; error = ''; notifyListeners();
    try {
      final data = await repository.fetchByDate(date);
      items = data;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }


}
