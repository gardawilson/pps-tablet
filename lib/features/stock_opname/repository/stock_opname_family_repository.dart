import 'dart:convert';
import 'package:flutter/foundation.dart'; // biar bisa pakai debugPrint
import 'package:http/http.dart' as http;

import '../../../../constants/api_constants.dart';
import '../../../../utils/token_storage.dart';
import '../model/stock_opname_family_model.dart';

class StockOpnameFamilyRepository {
  Future<List<StockOpnameFamily>> fetchFamilies(String noSO) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.noStockOpnameFamilies(noSO));

    debugPrint("📤 [fetchFamilies] GET $url");
    debugPrint("🔑 [fetchFamilies] Token: $token");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("📥 [fetchFamilies] Status: ${response.statusCode}");
    debugPrint("📥 [fetchFamilies] Raw Body: ${response.body}");

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      debugPrint("📦 [fetchFamilies] Decoded Body: $body");

      if (body is List) {
        final list = body.map((e) => StockOpnameFamily.fromJson(e)).toList();
        debugPrint("✅ [fetchFamilies] Parsed families count: ${list.length}");
        return list;
      } else if (body is Map && body.containsKey('data')) {
        final list = (body['data'] as List)
            .map((e) => StockOpnameFamily.fromJson(e))
            .toList();
        debugPrint("✅ [fetchFamilies] Parsed families count: ${list.length}");
        return list;
      }

      debugPrint("❌ [fetchFamilies] Unexpected format: $body");
      throw Exception('Format data tidak sesuai');
    }

    debugPrint("❌ [fetchFamilies] Failed (status: ${response.statusCode}) Body: ${response.body}");
    throw Exception('Gagal mengambil data families (status: ${response.statusCode})');
  }
}
