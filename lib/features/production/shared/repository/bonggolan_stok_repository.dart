import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/bonggolan_stok_item.dart';
import '../models/bonggolan_stok_label.dart';

class BonggolanStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<BonggolanStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBonggolanStok);

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
      throw Exception('Timeout mengambil data stok bonggolan');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data stok bonggolan (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BonggolanStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BonggolanStokLabel>> fetchLabel(int idBonggolan) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBonggolanStokLabel(idBonggolan));

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
      throw Exception('Timeout mengambil data label bonggolan');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data label bonggolan (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BonggolanStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
