// lib/features/warehouse/view_model/warehouse_view_model.dart
import 'package:flutter/foundation.dart';
import '../model/warehouse_model.dart';
import '../repository/warehouse_repository.dart';

class WarehouseViewModel extends ChangeNotifier {
  final WarehouseRepository repository;
  WarehouseViewModel({required this.repository});

  List<MstWarehouse> items = [];
  bool isLoading = false;
  String error = '';

  Future<void> loadAll({
    bool includeDisabled = false,
    String? q,
    String orderBy = 'NamaWarehouse',
    String orderDir = 'ASC',
  }) async {
    isLoading = true;
    error = '';
    notifyListeners();

    try {
      items = await repository.fetchAll(
        includeDisabled: includeDisabled,
        q: q,
        orderBy: orderBy,
        orderDir: orderDir,
      );
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
