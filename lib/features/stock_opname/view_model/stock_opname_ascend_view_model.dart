import 'package:flutter/material.dart';
import '../model/stock_opname_ascend_item_model.dart';
import '../repository/stock_opname_ascend_repository.dart';

class StockOpnameAscendViewModel extends ChangeNotifier {
  final StockOpnameAscendRepository repository;

  StockOpnameAscendViewModel({required this.repository});

  List<StockOpnameAscendItem> items = [];
  bool isLoading = false;
  String errorMessage = '';

  final Set<int> _fetchedUsageItems = {};
  final Set<int> _loadingUsageItems = {};

  bool hasFetchedUsage(int itemID) => _fetchedUsageItems.contains(itemID);
  bool isUsageLoading(int itemID) => _loadingUsageItems.contains(itemID);

  // Fetch items
  Future<void> fetchAscendItems(String noSO, int familyID, {String keyword = ''}) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      items = await repository.fetchAscendItems(noSO, familyID, keyword: keyword);
    } catch (e) {
      errorMessage = e.toString();
      items = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  // Fetch usage
  Future<void> fetchQtyUsage(int itemID, String tglSO, List<int> idWarehouses) async {
    if (_loadingUsageItems.contains(itemID) || _fetchedUsageItems.contains(itemID)) return;

    // kalau mau strict:
    if (idWarehouses.isEmpty) {
      debugPrint("QtyUsage LOG → wids kosong, skip fetch");
      return;
    }

    _loadingUsageItems.add(itemID);
    notifyListeners();

    try {
      final usage = await repository.fetchQtyUsage(itemID, tglSO, idWarehouses);

      debugPrint("QtyUsage LOG → hasil fetch itemID=$itemID, wids=$idWarehouses, usage=$usage");

      final index = items.indexWhere((e) => e.itemID == itemID);
      if (index != -1) {
        items[index].qtyUsage = usage;
        items[index].isUpdateUsage = true;
      }

      _fetchedUsageItems.add(itemID); // ✅ biar tidak fetch berulang
    } finally {
      _loadingUsageItems.remove(itemID);
      notifyListeners();
    }
  }


  // Save
  Future<bool> saveAscendItems(String noSO) async {
    if (items.isEmpty) return false;

    // ambil hanya item yang isUpdateUsage == true
    final updatedItems = items.where((e) => e.isUpdateUsage).toList();

    if (updatedItems.isEmpty) {
      debugPrint("SaveAscendItems LOG → tidak ada item yang diupdate, skip save.");
      return false;
    }

    debugPrint("SaveAscendItems LOG → menyimpan ${updatedItems.length} item yang diupdate");
    return repository.saveAscendItems(noSO, updatedItems);
  }


  // Delete
  Future<bool> deleteAscendItem(String noSO, int itemID, {TextEditingController? qtyCtrl}) async {
    final success = await repository.deleteAscendItem(noSO, itemID);
    if (success) {
      final index = items.indexWhere((e) => e.itemID == itemID);
      if (index != -1) {
        items[index].qtyFisik = null;
        items[index].qtyUsage = null;
        items[index].isUpdateUsage = false;
      }
      if (qtyCtrl != null) qtyCtrl.text = '';
      _fetchedUsageItems.remove(itemID);
      notifyListeners();
    }
    return success;
  }

  // Update / Reset
  void updateQtyFisik(int itemID, double value) {
    final index = items.indexWhere((e) => e.itemID == itemID);
    if (index != -1) {
      items[index].qtyFisik = value;
      notifyListeners();
    }
  }

  void updateUsage(int itemID, double value, String remark) {
    final index = items.indexWhere((e) => e.itemID == itemID);
    if (index != -1) {
      items[index].qtyUsage = value;
      items[index].usageRemark = remark;
      items[index].isUpdateUsage = true;
      notifyListeners();
    }
  }

  void resetQtyUsage(int itemID) {
    final index = items.indexWhere((e) => e.itemID == itemID);
    if (index != -1) {
      items[index].qtyUsage = -1;
      items[index].isUpdateUsage = false; // <- supaya fetch bisa jalan lagi
      _fetchedUsageItems.remove(itemID);  // <- reset cache
      debugPrint("QtyUsage LOG → reset itemID=$itemID, qtyUsage=-1, isUpdateUsage=false (cache dihapus)");
    }
    notifyListeners();
  }



  void reset() {
    items.clear();
    isLoading = false;
    errorMessage = '';
    _fetchedUsageItems.clear();
    _loadingUsageItems.clear();
    notifyListeners();
  }
}
