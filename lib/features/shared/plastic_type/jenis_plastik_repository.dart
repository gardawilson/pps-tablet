import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import 'jenis_plastik_model.dart';

class JenisPlastikRepository {
  Future<List<JenisPlastik>> fetchAll({bool onlyActive = true}) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/plastic-type");

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil jenis plastik (${res.statusCode})');
    }

    final body = json.decode(res.body);
    final List data = body['data'] ?? [];

    final items = data.map((e) => JenisPlastik.fromJson(e)).toList().cast<JenisPlastik>();
    if (onlyActive) {
      return items.where((e) => e.enable).toList();
    }
    return items;
  }
}
