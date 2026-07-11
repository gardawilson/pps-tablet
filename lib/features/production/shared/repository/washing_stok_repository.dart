import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/washing_stok_item.dart';
import '../models/washing_stok_label.dart';

class WashingStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<WashingStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstWashingStok);

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
      throw Exception('Timeout mengambil data stok washing');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok washing (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => WashingStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WashingStokLabel>> fetchLabel(int idWashing) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstWashingStokLabel(idWashing));

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
      throw Exception('Timeout mengambil data label washing');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label washing (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => WashingStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
