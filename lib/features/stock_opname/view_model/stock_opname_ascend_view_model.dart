import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/api_constants.dart';
import '../model/stock_opname_ascend_item_model.dart';

class StockOpnameAscendViewModel extends ChangeNotifier {
  // 🔹 State
  List<StockOpnameAscendItem> items = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';

  // 🔹 Track untuk QtyUsage
  final Set<int> _fetchedUsageItems = {};   // item yang sudah pernah fetch
  final Set<int> _loadingUsageItems = {};   // item yang sedang loading

  // =====================================================
  // 🔹 Helpers
  // =====================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  bool hasFetchedUsage(int itemID) => _fetchedUsageItems.contains(itemID);
  bool isUsageLoading(int itemID) => _loadingUsageItems.contains(itemID);

  // =====================================================
  // 🔹 Fetch Data
  // =====================================================

  Future<void> fetchAscendItems(
      String noSO,
      int familyID, {
        String keyword = '',
      }) async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/families/$familyID/ascend?keyword=$keyword',
      );

      debugPrint("📤 GET $url");

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      debugPrint("📥 Response [${response.statusCode}]");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        items = data.map((e) => StockOpnameAscendItem.fromJson(e)).toList();
      } else {
        hasError = true;
        errorMessage = 'Gagal mengambil data ascend (status: ${response.statusCode})';
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Kesalahan jaringan: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQtyUsage(int itemID, String tglSO) async {
    // ✅ Skip kalau sedang loading / sudah pernah fetch
    if (_loadingUsageItems.contains(itemID) || _fetchedUsageItems.contains(itemID)) {
      return;
    }

    _loadingUsageItems.add(itemID);
    notifyListeners();

    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/no-stock-opname/$itemID/usage?tglSO=$tglSO',
      );

      debugPrint("📤 GET $url");

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      debugPrint("📥 Response [${response.statusCode}]");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double usage = (data['qtyUsage'] as num?)?.toDouble() ?? 0.0;

        final index = items.indexWhere((e) => e.itemID == itemID);
        if (index != -1) {
          items[index].qtyUsage = usage;
          _fetchedUsageItems.add(itemID); // tandai sudah fetch
        }
      } else {
        debugPrint("❌ Gagal ambil usage (status: ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Exception fetchQtyUsage: $e");
    } finally {
      _loadingUsageItems.remove(itemID);
      notifyListeners();
    }
  }

  // =====================================================
  // 🔹 Save Data
  // =====================================================


  Future<bool> saveAscendItems(String noSO) async {
    if (items.isEmpty) return false;

    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/ascend/hasil',
      );

      // 🔹 Build payload langsung di ViewModel
      final body = {
        "dataList": items.map((e) => {
          "itemId": e.itemID,
          "qtyFound": e.qtyFisik,
          "qtyUsage": e.qtyUsage,
          "usageRemark": e.usageRemark,
          "isUpdateUsage": e.isUpdateUsage,
        }).toList()
      };

      debugPrint("📤 POST $url");
      debugPrint("📦 Payload: ${json.encode(body)}");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint("📥 Response [${response.statusCode}]: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Exception saveAscendItems: $e');
      return false;
    }
  }


  Future<bool> deleteAscendItem(String noSO, int itemID, {TextEditingController? qtyCtrl}) async {
    try {
      final token = await _getToken();
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/ascend/hasil/$itemID',
      );

      debugPrint("🗑 DELETE $url");

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("📥 Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final index = items.indexWhere((e) => e.itemID == itemID);
        if (index != -1) {
          items[index].qtyFisik = null;
          items[index].qtyUsage = -1.0;
          items[index].isUpdateUsage = false;
        }

        // ✅ reset controller juga
        if (qtyCtrl != null) {
          qtyCtrl.text = ""; // kosongkan text field
        }

        _fetchedUsageItems.remove(itemID); // supaya bisa fetch ulang
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception deleteAscendItem: $e');
      return false;
    }
  }





  // =====================================================
  // 🔹 Update / Reset State
  // =====================================================

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
      items[index].qtyUsage = -1.0;
    }
    _fetchedUsageItems.remove(itemID); // supaya bisa fetch ulang
    notifyListeners();
  }

  void reset() {
    items.clear();
    isLoading = false;
    hasError = false;
    errorMessage = '';
    _fetchedUsageItems.clear();
    _loadingUsageItems.clear();
    notifyListeners();
  }
}
