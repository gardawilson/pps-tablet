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
  Future<void> fetchQtyUsage(int itemID, String tglSO) async {
    if (_loadingUsageItems.contains(itemID) || _fetchedUsageItems.contains(itemID)) return;

    _loadingUsageItems.add(itemID);
    notifyListeners();

    try {
      final usage = await repository.fetchQtyUsage(itemID, tglSO);
      final index = items.indexWhere((e) => e.itemID == itemID);
      if (index != -1) {
        items[index].qtyUsage = usage;
        _fetchedUsageItems.add(itemID);
      }
    } finally {
      _loadingUsageItems.remove(itemID);
      notifyListeners();
    }
  }

  // Save
  Future<bool> saveAscendItems(String noSO) async {
    if (items.isEmpty) return false;
    return repository.saveAscendItems(noSO, items);
  }

  // Delete
  Future<bool> deleteAscendItem(String noSO, int itemID, {TextEditingController? qtyCtrl}) async {
    final success = await repository.deleteAscendItem(noSO, itemID);
    if (success) {
      final index = items.indexWhere((e) => e.itemID == itemID);
      if (index != -1) {
        items[index].qtyFisik = null;
        items[index].qtyUsage = -1.0;
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
    if (index != -1) items[index].qtyUsage = -1.0;
    _fetchedUsageItems.remove(itemID);
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
