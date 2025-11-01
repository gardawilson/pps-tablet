// lib/features/shared/bonggolan_type/jenis_bonggolan_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/jenis_bonggolan_model.dart';

class JenisBonggolanRepository {
  /// Backend already returns only active (Enable = 1)
  Future<List<JenisBonggolan>> fetchAllActive() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/bonggolan-type");

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil jenis bonggolan (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => JenisBonggolan.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
