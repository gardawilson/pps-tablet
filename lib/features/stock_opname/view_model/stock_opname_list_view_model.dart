import 'package:flutter/material.dart';
import '../model/stock_opname_model.dart';
import '../repository/stock_opname_repository.dart';

class StockOpnameViewModel extends ChangeNotifier {
  final StockOpnameRepository repository;

  StockOpnameViewModel({required this.repository});

  List<StockOpname> _stockOpnameList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<StockOpname> get stockOpnameList => _stockOpnameList;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchStockOpname() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _stockOpnameList = await repository.fetchStockOpnameList();
    } catch (e) {
      _stockOpnameList = [];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _stockOpnameList.clear();
    _isLoading = false;
    _errorMessage = '';
    notifyListeners();
  }
}
