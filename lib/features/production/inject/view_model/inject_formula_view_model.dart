// lib/features/production/inject/view_model/inject_formula_view_model.dart

import 'package:flutter/foundation.dart';

import '../model/inject_formula_model.dart';
import '../repository/inject_formula_repository.dart';

class InjectFormulaViewModel extends ChangeNotifier {
  final InjectFormulaRepository _repo;

  InjectFormulaViewModel({InjectFormulaRepository? repo})
      : _repo = repo ?? InjectFormulaRepository();

  InjectFormulaData? _data;
  bool _isLoading = false;
  String? _error;

  InjectFormulaData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(String noProduksi) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repo.fetch(noProduksi);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
