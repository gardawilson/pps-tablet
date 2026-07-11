import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/bahan_baku_proses_label.dart';
import '../models/stok_bahan_baku_item.dart';

class StokBahanBakuRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<StokBahanBakuItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.stokBahanBakuProses);

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
      throw Exception('Timeout mengambil data stok bahan baku');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data stok bahan baku (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => StokBahanBakuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BahanBakuProsesLabel>> fetchLabel(int idJenis) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.stokBahanBakuProsesLabel(idJenis));

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
      throw Exception('Timeout mengambil data label bahan baku');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data label bahan baku (${res.statusCode})');
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => BahanBakuProsesLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
