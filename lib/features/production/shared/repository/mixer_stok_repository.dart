import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/mixer_stok_item.dart';
import '../models/mixer_stok_label.dart';

class MixerStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<MixerStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstMixerStok);

    late http.Response res;
    try {
      res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data stok mixer');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok mixer (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => MixerStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MixerStokLabel>> fetchLabel(int idMixer) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstMixerStokLabel(idMixer));

    late http.Response res;
    try {
      res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data label mixer');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label mixer (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => MixerStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
