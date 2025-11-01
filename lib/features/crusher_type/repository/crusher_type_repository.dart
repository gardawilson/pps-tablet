import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/crusher_type_model.dart';

class CrusherTypeRepository {
  /// Backend returns only active (Enable = 1)
  Future<List<CrusherType>> fetchAllActive() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/crusher-type");

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil jenis crusher (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => CrusherType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
