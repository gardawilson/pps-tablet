import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/gilingan_type_model.dart';

class GilinganTypeRepository {
  /// Backend returns only active (Enable = 1)
  Future<List<GilinganType>> fetchAllActive() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/gilingan-type");
    // If you mounted it under /api/master/gilingan-type, change to:
    // final url = Uri.parse("${ApiConstants.baseUrl}/api/master/gilingan-type");

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch gilingan types (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => GilinganType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
