import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/broker_stok_item.dart';
import '../models/broker_stok_label.dart';

class BrokerStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<BrokerStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBrokerStok);

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
      throw Exception('Timeout mengambil data stok broker');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok broker (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BrokerStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BrokerStokLabel>> fetchLabel(int idBroker) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBrokerStokLabel(idBroker));

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
      throw Exception('Timeout mengambil data label broker');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label broker (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BrokerStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
