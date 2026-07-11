import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../models/furniture_wip_stok_item.dart';
import '../models/furniture_wip_stok_label.dart';

class FurnitureWipStokRepository {
  static const _timeout = Duration(seconds: 25);

  Future<List<FurnitureWipStokItem>> fetchStok() async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstFurnitureWipStok);

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
      throw Exception('Timeout mengambil data stok furniture WIP');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data stok furniture WIP (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => FurnitureWipStokItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FurnitureWipStokLabel>> fetchLabel(int idCabinetWip) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse(ApiConstants.mstFurnitureWipStokLabel(idCabinetWip));

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
      throw Exception('Timeout mengambil data label furniture WIP');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data label furniture WIP (${res.statusCode})',
      );
    }

    final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List dataList = (body['data'] ?? []) as List;
    return dataList
        .map((e) => FurnitureWipStokLabel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
