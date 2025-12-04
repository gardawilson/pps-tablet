// lib/features/shared/inject_production/hot_stamp_production_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/inject_production_model.dart';

class InjectProductionRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// 🔹 Fetch InjectProduksi_h by date (YYYY-MM-DD)
  Future<List<InjectProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date); // YYYY-MM-DD
    // Backend path: /api/production/inject/:date
    final url = Uri.parse('$_base/api/production/inject/$dateDb');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data inject produksi (byDate)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print(
      '⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms',
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data inject produksi (${res.statusCode})',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map(
          (e) => InjectProduction.fromJson(e as Map<String, dynamic>),
    )
        .toList();
  }

  /// 🔹 Fetch FurnitureWIP list by NoProduksi Inject
  /// Backend path: /api/production/inject/furniture-wip/:noProduksi
  Future<List<FurnitureWipByInjectProduction>>
  fetchFurnitureWipByInjectProduction(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url =
    Uri.parse('$_base/api/production/inject/furniture-wip/$noProduksi');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'Timeout mengambil data FurnitureWIP by InjectProduksi',
      );
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print(
      '⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms',
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data FurnitureWIP by InjectProduksi (${res.statusCode})',
      );
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;

    final List list = (body['data'] ?? []) as List;

    return list
        .map(
          (e) => FurnitureWipByInjectProduction.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}
