import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/reject_stok_item.dart';
import '../models/reject_stok_label.dart';

class RejectStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<RejectStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.rejectTypeStok);

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
      throw Exception('Timeout mengambil data stok reject');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok reject (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => RejectStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RejectStokLabel>> fetchLabel(int idReject) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.rejectTypeStokLabel(idReject));

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
      throw Exception('Timeout mengambil data label reject');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label reject (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => RejectStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
