import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/barang_jadi_stok_item.dart';
import '../models/barang_jadi_stok_label.dart';

class BarangJadiStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<BarangJadiStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBarangJadiStok);

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
      throw Exception('Timeout mengambil data stok barang jadi');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data stok barang jadi (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BarangJadiStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BarangJadiStokLabel>> fetchLabel(int idBJ) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstBarangJadiStokLabel(idBJ));

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
      throw Exception('Timeout mengambil data label barang jadi');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data label barang jadi (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BarangJadiStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
