// lib/features/shared/washing_production/washing_production_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../../../core/network/endpoints.dart';
import '../../../core/services/token_storage.dart';
import 'washing_production_model.dart';

class WashingProductionRepository {
  Future<List<WashingProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();

    // ⬅️ Pastikan hanya tanggal (tanpa jam)
    final dateDb = toDbDateString(date);

    // Opsi A: tetap pakai path segment
    final url = Uri.parse('${ApiConstants.baseUrl}/api/production/washing/$dateDb');

    // Opsi B (lebih aman untuk karakter): pakai query param
    // final url = Uri.parse('${ApiConstants.baseUrl}/api/production/washing')
    //     .replace(queryParameters: {'date': dateDb});

    // ====== LOG REQUEST ======
    final started = DateTime.now();
    print('➡️ [GET] $url');
    print('   Headers: { Authorization: Bearer ****, Accept: application/json }');

    http.Response res;
    try {
      res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final dur = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${dur}ms');

    const maxLen = 2000;
    final bodyStr = res.body;
    print('📦 Body: ${bodyStr.length > maxLen ? bodyStr.substring(0, maxLen) + '…(truncated)' : bodyStr}');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data washing produksi (${res.statusCode})');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => WashingProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
