// lib/features/supplier/repository/supplier_repository.dart
//
// NOTE: endpoint `GET /api/mst/supplier` belum ada di backend saat modul
// Penerimaan Bahan Baku ini dibuat — mengikuti konvensi endpoint master data
// lain (mis. `/api/mst/warehouse`, `/api/mst/regu`). Perlu diimplementasikan
// oleh tim backend sebelum dropdown Supplier bisa berfungsi.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import '../model/supplier_model.dart';

class SupplierRepository {
  static const _timeout = Duration(seconds: 25);
  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Future<List<MstSupplier>> fetchAll({String? q}) async {
    final token = await TokenStorage.getToken();
    final params = <String, String>{};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final url = Uri.parse(
      '$_base/api/mst/supplier',
    ).replace(queryParameters: params.isEmpty ? null : params);

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data supplier');
    }

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data supplier (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => MstSupplier.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
