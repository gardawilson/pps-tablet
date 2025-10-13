import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/stock_opname_model.dart';

class StockOpnameRepository {
  Future<List<StockOpname>> fetchStockOpnameList() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.listNoSO);

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      if (body is List) {
        return body.map((e) => StockOpname.fromJson(e)).toList();
      } else if (body is Map && body.containsKey('data')) {
        return (body['data'] as List)
            .map((e) => StockOpname.fromJson(e))
            .toList();
      } else {
        throw Exception('Format data tidak sesuai');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Token is invalid or expired');
    } else {
      final body = json.decode(response.body);
      throw Exception(
          body['message'] ?? 'Tidak ada Jadwal Stock Opname saat ini');
    }
  }
}
