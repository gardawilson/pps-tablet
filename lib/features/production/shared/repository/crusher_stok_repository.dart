import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/crusher_stok_item.dart';
import '../models/crusher_stok_label.dart';

class CrusherStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<CrusherStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstCrusherStok);

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
      throw Exception('Timeout mengambil data stok crusher');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok crusher (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => CrusherStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CrusherStokLabel>> fetchLabel(int idCrusher) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstCrusherStokLabel(idCrusher));

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
      throw Exception('Timeout mengambil data label crusher');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label crusher (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => CrusherStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
