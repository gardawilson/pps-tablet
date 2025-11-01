import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/mesin_model.dart';

class MesinRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Fetch mesin by bagian (exact string after TRIM on BE).
  /// includeDisabled: pass true to include Enable = 0 (default false → only active).
  Future<List<MstMesin>> fetchByBagian({
    required String bagian,
    bool includeDisabled = false,
  }) async {
    final token = await TokenStorage.getToken();
    final enc = Uri.encodeComponent(bagian);
    final qs = includeDisabled ? '?includeDisabled=1' : '';
    final url = Uri.parse('$_base/api/master-mesin/$enc$qs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data mesin untuk bagian "$bagian"');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data mesin (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list.map((e) => MstMesin.fromJson(e as Map<String, dynamic>)).toList();
  }
}
