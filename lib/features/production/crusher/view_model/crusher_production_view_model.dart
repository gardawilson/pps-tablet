import 'package:flutter/foundation.dart';
import '../model/crusher_production_model.dart';
import '../repository/crusher_production_repository.dart';

class CrusherProductionViewModel extends ChangeNotifier {
  final CrusherProductionRepository repository;
  CrusherProductionViewModel({required this.repository});

  List<CrusherProduction> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> fetchByDate(
      DateTime date, {
        int? idMesin,
        String? shift,
      }) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchByDate(date, idMesin: idMesin, shift: shift);
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
