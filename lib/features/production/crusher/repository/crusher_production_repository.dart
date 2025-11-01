import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/crusher_production_model.dart';


class CrusherProductionRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Optional: filter by idMesin and/or shift (server supports it)
  Future<List<CrusherProduction>> fetchByDate(
      DateTime date, {
        int? idMesin,
        String? shift,
      }) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date); // YYYY-MM-DD

    // If you mounted under '/api/production/crusher/:date' (recommended):
    var url = Uri.parse('$_base/api/production/crusher/$dateDb');

    // If instead you mounted '/api/crusher/:date', use:
    // var url = Uri.parse('$_base/api/crusher/$dateDb');

    final qp = <String, String>{};
    if (idMesin != null) qp['idMesin'] = '$idMesin';
    if (shift != null && shift.isNotEmpty) qp['shift'] = shift;
    if (qp.isNotEmpty) {
      url = url.replace(queryParameters: qp);
    }

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data crusher produksi (byDate)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data crusher produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => CrusherProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
