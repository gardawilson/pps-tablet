import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/mixer_type_model.dart';

class MixerTypeRepository {
  /// Backend returns only active (Enable = 1)
  Future<List<MixerType>> fetchAllActive() async {
    final token = await TokenStorage.getToken();

    // pastikan tidak double slash
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');
    final url = Uri.parse('$base/api/mixer-type');

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil jenis mixer (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List data = (body['data'] ?? []) as List;

    return data
        .map((e) => MixerType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
