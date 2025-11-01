// lib/features/shared/washing_production/washing_production_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/washing_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class WashingProductionRepository {
  static const _timeout = Duration(seconds: 25);

  /// Helper: base URL tanpa trailing slash
  String get _base =>
      ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // =========================
  //  BY DATE (tetap ada)
  // =========================
  Future<List<WashingProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date);
    final url = Uri.parse('$_base/api/production/washing/$dateDb');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data washing produksi (byDate)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data washing produksi (${res.statusCode})');
    }

    // Pastikan decoding UTF-8 aman
    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => WashingProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST (untuk infinite pagination)
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,

    // opsi filter tambahan (opsional, siap pakai kalau backend mendukung)
    String? search,
    int? shift,
    DateTime? date, // misal filter per tanggal
  }) async {
    final token = await TokenStorage.getToken();

    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (search != null && search.isNotEmpty) 'search': search,
      if (shift != null) 'shift': '$shift',
      if (date != null) 'date': toDbDateString(date),
    };

    final url = Uri.parse('$_base/api/production/washing')
        .replace(queryParameters: qp);

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil list washing produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil list washing produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => WashingProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    // Meta (fallback aman jika server tidak kirim sebagian field)
    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print('✅ Parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items,           // List<WashingProduction>
      'page': currentPage,      // int
      'totalPages': totalPages, // int
      'total': totalData,       // int
    };
  }

  /// Helper kalau hanya butuh list halaman tertentu
  Future<List<WashingProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    int? shift,
    DateTime? date,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      shift: shift,
      date: date,
    );
    return (r['items'] as List<WashingProduction>);
  }
}
