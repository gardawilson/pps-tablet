import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/regu_model.dart';

class ReguRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Future<List<MstRegu>> fetchAll({int? idBagian, List<int>? idBagianList}) async {
    final token = await TokenStorage.getToken();
    String query = '';
    if (idBagianList != null && idBagianList.isNotEmpty) {
      query = '?idBagian=${idBagianList.join(',')}';
    } else if (idBagian != null) {
      query = '?idBagian=$idBagian';
    }
    final uri = Uri.parse('$_base/api/mst/regu$query');

    final started = DateTime.now();
    print('📡 [GET] $uri');

    late http.Response res;
    try {
      res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data regu');
    } catch (e) {
      print('✖ Request error: $e');
      rethrow;
    }

    print('⌛ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data regu (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list.map((e) => MstRegu.fromJson(e as Map<String, dynamic>)).toList();
  }
}
