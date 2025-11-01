import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import 'lokasi_model.dart';

class LokasiRepository {
  Future<List<Lokasi>> fetchLokasiList() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/api/mst-lokasi');

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body['success'] == true && body['data'] is List) {
        return (body['data'] as List).map((e) => Lokasi.fromJson(e)).toList();
      }
      throw Exception(body['message'] ?? 'Format data tidak sesuai');
    }
    throw Exception('Gagal mengambil lokasi (status: ${res.statusCode})');
  }
}
