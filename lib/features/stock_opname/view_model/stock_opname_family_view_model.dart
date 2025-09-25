import 'package:flutter/material.dart';
import '../model/stock_opname_family_model.dart';
import '../repository/stock_opname_family_repository.dart';

class StockOpnameFamilyViewModel extends ChangeNotifier {
  final StockOpnameFamilyRepository repository;

  StockOpnameFamilyViewModel({required this.repository});

  List<StockOpnameFamily> families = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchFamilies(String noSO) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      families = await repository.fetchFamilies(noSO);
    } catch (e) {
      families = [];
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    families.clear();
    isLoading = false;
    errorMessage = '';
    notifyListeners();
  }
}
