import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/broker_inputs_model.dart';
import '../model/broker_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class BrokerProductionRepository {
  static const _timeout = Duration(seconds: 25);

  // Simple in-memory cache for inputs
  final Map<String, BrokerInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // =========================
  //  BY DATE (tetap ada)
  // =========================
  Future<List<BrokerProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date);
    final url = Uri.parse('$_base/api/production/broker/$dateDb');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil data broker produksi (byDate)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data broker produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;
    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => BrokerProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST (infinite scroll style)
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,

    // Text search for NoProduksi (contains)
    String? search,

    // VM convenience: prefer this if provided; if exactNoProduksi == true we still send as contains
    String? noProduksi,
    bool exactNoProduksi = false, // backend currently does LIKE only

    // Other optional filters (supported by backend)
    int? shift,
    DateTime? date,               // legacy single date -> maps to dateFrom/dateTo
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idMesin,
    int? idOperator,
  }) async {
    final token = await TokenStorage.getToken();

    // Prefer explicit noProduksi over generic search
    final String? effectiveSearch = (noProduksi != null && noProduksi.trim().isNotEmpty)
        ? noProduksi.trim()
        : (search != null && search.trim().isNotEmpty ? search.trim() : null);

    // Map dates: if range not provided but single `date` is set, use it for both from/to
    final String? df = dateFrom != null
        ? toDbDateString(dateFrom)
        : (date != null ? toDbDateString(date) : null);

    final String? dt = dateTo != null
        ? toDbDateString(dateTo)
        : (date != null ? toDbDateString(date) : null);

    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (effectiveSearch != null) 'search': effectiveSearch, // API searches NoProduksi only
      if (shift != null) 'shift': '$shift',
      if (df != null) 'dateFrom': df,
      if (dt != null) 'dateTo': dt,
      if (idMesin != null) 'idMesin': '$idMesin',
      if (idOperator != null) 'idOperator': '$idOperator',
    };

    final url = Uri.parse('$_base/api/production/broker').replace(queryParameters: qp);

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil list broker produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil list broker produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => BrokerProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print('✅ Broker parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items,           // List<BrokerProduction>
      'page': currentPage,      // int
      'totalPages': totalPages, // int
      'total': totalData,       // int
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<BrokerProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
    bool exactNoProduksi = false,
    int? shift,
    DateTime? date,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idMesin,
    int? idOperator,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noProduksi: noProduksi,
      exactNoProduksi: exactNoProduksi,
      shift: shift,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
      idMesin: idMesin,
      idOperator: idOperator,
    );
    return (r['items'] as List<BrokerProduction>);
  }

  // Optional: parse on an isolate for large JSON
  static BrokerInputs _parseInputs(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw FormatException('Response tidak valid: field data kosong');
    }
    return BrokerInputs.fromJson(data);
  }

  Future<BrokerInputs> fetchInputs(String noProduksi, {bool force = false}) async {
    if (!force && _inputsCache.containsKey(noProduksi)) {
      return _inputsCache[noProduksi]!;
    }

    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi/inputs');

    final started = DateTime.now();
    print('➡️ [GET] $url');

    http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil input ($noProduksi)');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    final elapsedMs = DateTime.now().difference(started).inMilliseconds;
    print('⬅️ [${res.statusCode}] in ${elapsedMs}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil input ($noProduksi), code ${res.statusCode})');
    }

    // Decode safely (handles non-ASCII)
    final decoded = utf8.decode(res.bodyBytes);

    // Parse JSON (optionally via compute to keep UI smooth for large payloads)
    Map<String, dynamic> body;
    try {
      body = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response bukan JSON valid: $e');
    }

    final inputs = await compute(_parseInputs, body);

    _inputsCache[noProduksi] = inputs;
    return inputs;
  }

  void invalidateInputs(String noProduksi) => _inputsCache.remove(noProduksi);
  void clearCache() => _inputsCache.clear();
}

