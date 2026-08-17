// lib/features/supplier/view_model/supplier_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/supplier_model.dart';
import '../repository/supplier_repository.dart';

class SupplierViewModel extends ChangeNotifier {
  final SupplierRepository repository;
  SupplierViewModel({required this.repository});

  List<MstSupplier> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll({String? q}) async {
    isLoading = true;
    error = '';
    notifyListeners();
    try {
      items = await repository.fetchAll(q: q);
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
