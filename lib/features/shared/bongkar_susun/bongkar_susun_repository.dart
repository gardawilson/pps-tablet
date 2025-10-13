import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/network/endpoints.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/token_storage.dart';
import 'bongkar_susun_model.dart';

class BongkarSusunRepository {
  Future<List<BongkarSusun>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date);
    final url = Uri.parse('${ApiConstants.baseUrl}/api/bongkar-susun/$dateDb');

    final started = DateTime.now();
    print('➡️ [GET] $url');
    print('   Headers: { Authorization: Bearer ****, Accept: application/json }');

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    final dur = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${dur}ms');
    const maxLen = 2000;
    final bodyStr = res.body;
    print('📦 Body: ${bodyStr.length > maxLen ? bodyStr.substring(0, maxLen) + '…(truncated)' : bodyStr}');

    if (res.statusCode == 404) return <BongkarSusun>[]; // treat as kosong
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data BongkarSusun (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;
    return list.map((e) => BongkarSusun.fromJson(e as Map<String, dynamic>)).toList();
  }
}
