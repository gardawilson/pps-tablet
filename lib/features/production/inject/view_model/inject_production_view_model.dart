// lib/features/shared/inject_production/view_model/hot_stamp_production_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/inject_production_model.dart';
import '../repository/inject_production_repository.dart';

class InjectProductionViewModel extends ChangeNotifier {
  final InjectProductionRepository repository;
  InjectProductionViewModel({required this.repository});

  // 🔹 Data Inject by date
  List<InjectProduction> items = [];
  bool isLoading = false;
  String error = '';

  // 🔹 Data FurnitureWIP by InjectProduksi (NoProduksi)
  List<FurnitureWipByInjectProduction> furnitureWipItems = [];
  bool isLoadingFurnitureWip = false;
  String furnitureWipError = '';

  // ---------------------------------------------------------------------------
  // Fetch InjectProduksi_h by date
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Fetch FurnitureWIP list by NoProduksi Inject
  // ---------------------------------------------------------------------------
  Future<void> fetchFurnitureWipByInjectProduction(String noProduksi) async {
    isLoadingFurnitureWip = true;
    furnitureWipError = '';
    furnitureWipItems = [];
    notifyListeners();

    try {
      furnitureWipItems =
      await repository.fetchFurnitureWipByInjectProduction(noProduksi);
    } catch (e) {
      furnitureWipError = e.toString();
      furnitureWipItems = [];
    } finally {
      isLoadingFurnitureWip = false;
      notifyListeners();
    }
  }

  void clear() {
    items = [];
    error = '';
    isLoading = false;

    furnitureWipItems = [];
    furnitureWipError = '';
    isLoadingFurnitureWip = false;

    notifyListeners();
  }
}
