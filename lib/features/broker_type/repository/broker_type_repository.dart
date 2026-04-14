import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/broker_type_model.dart';

class BrokerTypeRepository {
  Future<List<BrokerType>> fetchAllActive() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBroker);

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil jenis broker (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      throw Exception(
        body['message']?.toString() ?? 'Gagal mengambil data broker',
      );
    }

    final List data = (body['data'] ?? []) as List;
    return data
        .map((e) => BrokerType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
