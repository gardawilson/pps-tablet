import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import 'max_sak_model.dart';

class MaxSakRepository {
  Future<MaxSakDefaults> fetch(int idBagian) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/max-sak/$idBagian");

    final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode != 200) {
      throw Exception('Gagal ambil max-sak (status: ${resp.statusCode})');
    }

    final body = json.decode(resp.body);
    final data = body['data'] ?? {};
    final jlh = (data['JlhSak'] ?? 1) as int;
    final kgNum = data['DefaultKG'];
    final kg = (kgNum is num) ? kgNum.toDouble() : 1.0;
    return MaxSakDefaults(jlhSak: jlh, defaultKg: kg);
  }
}
