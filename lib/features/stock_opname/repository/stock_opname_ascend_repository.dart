import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/stock_opname_ascend_item_model.dart';

class StockOpnameAscendRepository {
  // 🔹 Fetch daftar item ascend
  Future<List<StockOpnameAscendItem>> fetchAscendItems(
      String noSO, int familyID,
      {String keyword = ''}) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(
      ApiConstants.noStockOpnameAscendItems(noSO, familyID, keyword: keyword),
    );

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((e) => StockOpnameAscendItem.fromJson(e)).toList();
      }
      throw Exception('Format data tidak sesuai');
    }
    throw Exception('Gagal mengambil data ascend (status: ${response.statusCode})');
  }

// 🔹 Fetch QtyUsage
// Tambahkan parameter String wids
  Future<double> fetchQtyUsage(int itemID, String tglSO, List<int> idWarehouses) async {
    final wids = idWarehouses.where((e) => e > 0).join(',');
    if (wids.isEmpty) throw Exception('wids kosong');

    final token = await TokenStorage.getToken();
    final url = ApiConstants.noStockOpnameUsage(itemID, tglSO, wids);

    debugPrint("QtyUsage LOG → REQUEST URL: ${url.toString()}"); // ✅ ini

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("QtyUsage LOG → RESPONSE: ${response.statusCode} ${response.reasonPhrase}");
    // optional: debugPrint("QtyUsage LOG → BODY: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return (body['qtyUsage'] as num?)?.toDouble() ?? 0.0;
    } else {
      final errorBody = json.decode(response.body);
      final errorMessage = errorBody['message'] ?? 'Gagal ambil usage';
      throw Exception('Gagal ambil usage (status: ${response.statusCode}, pesan: $errorMessage)');
    }
  }



  // 🔹 Save items
  Future<bool> saveAscendItems(String noSO, List<StockOpnameAscendItem> items) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.noStockOpnameSave(noSO));

    final body = {
      "dataList": items.map((e) => {
        "itemId": e.itemID,
        "qtyFound": e.qtyFisik,
        "qtyUsage": e.qtyUsage,
        "usageRemark": e.usageRemark,
        "isUpdateUsage": e.isUpdateUsage,
      }).toList()
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  // 🔹 Delete item
  Future<bool> deleteAscendItem(String noSO, int itemID) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.noStockOpnameDelete(noSO, itemID));

    final response = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200;
  }
}
