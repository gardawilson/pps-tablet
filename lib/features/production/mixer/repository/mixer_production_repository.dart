// lib/features/shared/mixer_production/gilingan_production_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/mixer_production_model.dart';

class MixerProductionRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Ambil data MixerProduksi_h per tanggal (backend: GET /api/production/mixer/:date)
  Future<List<MixerProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date); // YYYY-MM-DD
    final url = Uri.parse('$_base/api/production/mixer/$dateDb');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data mixer produksi (byDate)');
    } catch (e) {
      print('❌ Request error (mixer byDate): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in '
        '${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data mixer produksi (${res.statusCode})',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => MixerProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
