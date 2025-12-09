// lib/features/shared/inject_production/view_model/inject_production_view_model.dart
import 'package:flutter/foundation.dart';

import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/packing_by_inject_production_model.dart';
import '../model/inject_production_model.dart';
import '../repository/inject_production_repository.dart';

class InjectProductionViewModel extends ChangeNotifier {
  final InjectProductionRepository repository;

  InjectProductionViewModel({required this.repository});

  // ---------------------------------------------------------------------------
  // InjectProduksi_h by date
  // ---------------------------------------------------------------------------
  List<InjectProduction> items = [];
  bool isLoading = false;
  String error = '';

  // ---------------------------------------------------------------------------
  // FurnitureWIP by InjectProduksi (NoProduksi)
  // ---------------------------------------------------------------------------
  FurnitureWipByInjectResult? furnitureWipResult;
  bool isLoadingFurnitureWip = false;
  String furnitureWipError = '';

  /// BeratProdukHasilTimbang dari Inject (bisa null)
  double? get furnitureWipBeratProdukHasilTimbang =>
      furnitureWipResult?.beratProdukHasilTimbang;

  /// List kandidat Furniture WIP
  List<FurnitureWipByInjectItem> get furnitureWipItems =>
      furnitureWipResult?.items ?? const [];

  // ---------------------------------------------------------------------------
  // Packing (BarangJadi) by InjectProduksi (NoProduksi)
  // ---------------------------------------------------------------------------
  PackingByInjectResult? packingResult;
  bool isLoadingPacking = false;
  String packingError = '';

  /// BeratProdukHasilTimbang dari Inject (bisa null)
  double? get packingBeratProdukHasilTimbang =>
      packingResult?.beratProdukHasilTimbang;

  /// List kandidat Barang Jadi
  List<PackingByInjectItem> get packingItems =>
      packingResult?.items ?? const [];

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
  // Fetch FurnitureWIP (kandidat) by NoProduksi Inject
  // ---------------------------------------------------------------------------
  Future<void> fetchFurnitureWipByInjectProduction(String noProduksi) async {
    isLoadingFurnitureWip = true;
    furnitureWipError = '';
    furnitureWipResult = null;
    notifyListeners();

    try {
      furnitureWipResult =
      await repository.fetchFurnitureWipByInjectProduction(noProduksi);
    } catch (e) {
      furnitureWipError = e.toString();
      furnitureWipResult = null;
    } finally {
      isLoadingFurnitureWip = false;
      notifyListeners();
    }
  }

  void clearFurnitureWip() {
    furnitureWipResult = null;
    furnitureWipError = '';
    isLoadingFurnitureWip = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Fetch Packing (BarangJadi) kandidat by NoProduksi Inject
  // ---------------------------------------------------------------------------
  Future<void> fetchPackingByInjectProduction(String noProduksi) async {
    isLoadingPacking = true;
    packingError = '';
    packingResult = null;
    notifyListeners();

    try {
      packingResult =
      await repository.fetchPackingByInjectProduction(noProduksi);
    } catch (e) {
      packingError = e.toString();
      packingResult = null;
    } finally {
      isLoadingPacking = false;
      notifyListeners();
    }
  }

  void clearPacking() {
    packingResult = null;
    packingError = '';
    isLoadingPacking = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Reset semua state
  // ---------------------------------------------------------------------------
  void clear() {
    // Inject list
    items = [];
    error = '';
    isLoading = false;

    // Furniture WIP
    furnitureWipResult = null;
    furnitureWipError = '';
    isLoadingFurnitureWip = false;

    // Packing
    packingResult = null;
    packingError = '';
    isLoadingPacking = false;

    notifyListeners();
  }
}
