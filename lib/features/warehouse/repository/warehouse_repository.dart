// lib/features/warehouse/repository/warehouse_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/warehouse_model.dart';

class WarehouseRepository {
  static const _timeout = Duration(seconds: 25);
  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Future<http.Response> _get(Uri url) async {
    final token = await TokenStorage.getToken();
    final started = DateTime.now();
    print('➡️ [GET] $url');
    try {
      final res = await http.get(url, headers: _headers(token)).timeout(_timeout);
      print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');
      return res;
    } on TimeoutException {
      throw Exception('Timeout saat mengambil data dari $url');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
  }

  /// Ambil semua warehouse (tanpa pagination) dari /api/mst/warehouse
  /// includeDisabled: true => sertakan Enable = 0
  /// q: opsional, search by NamaWarehouse (LIKE %q%)
  /// orderBy/orderDir: opsional; default NamaWarehouse ASC (ikut BE whitelist)
  Future<List<MstWarehouse>> fetchAll({
    bool includeDisabled = false,
    String? q,
    String orderBy = 'NamaWarehouse',
    String orderDir = 'ASC',
  }) async {
    final params = <String, String>{};
    if (includeDisabled) params['includeDisabled'] = '1';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (orderBy.isNotEmpty) params['orderBy'] = orderBy;
    if (orderDir.isNotEmpty) params['orderDir'] = orderDir.toUpperCase();

    final uri = Uri.parse('$_base/api/mst/warehouse')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await _get(uri);

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data warehouse (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => MstWarehouse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
