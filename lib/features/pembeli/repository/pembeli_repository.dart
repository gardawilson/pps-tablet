import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/pembeli_model.dart';

class PembeliRepository {
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
      final res =
      await http.get(url, headers: _headers(token)).timeout(_timeout);
      print(
          '⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');
      return res;
    } on TimeoutException {
      throw Exception('Timeout saat mengambil data dari $url');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }
  }

  /// Ambil semua pembeli (tanpa pagination) dari /api/mst-pembeli
  /// includeDisabled: true => sertakan Enable = 0
  /// q: opsional, search by NamaPembeli (LIKE %q%)
  /// orderBy/orderDir: opsional; default NamaPembeli ASC (ikuti BE whitelist)
  Future<List<MstPembeli>> fetchAll({
    bool includeDisabled = false,
    String? q,
    String orderBy = 'NamaPembeli',
    String orderDir = 'ASC',
  }) async {
    final params = <String, String>{};
    if (includeDisabled) params['includeDisabled'] = '1';
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (orderBy.isNotEmpty) params['orderBy'] = orderBy;
    if (orderDir.isNotEmpty) params['orderDir'] = orderDir.toUpperCase();

    final uri = Uri.parse('$_base/api/mst/pembeli')
        .replace(queryParameters: params.isEmpty ? null : params);

    final res = await _get(uri);

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data pembeli (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => MstPembeli.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
