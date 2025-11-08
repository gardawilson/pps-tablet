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

  // =========================
  //  CREATE (POST)
  // =========================
  Future<BrokerProduction> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jam, // int atau 'HH:mm-HH:mm'
    required int shift,
    String? hourStart,    // ⬅️ baru
    String? hourEnd,      // ⬅️ baru
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker');

    final tglStr = toDbDateString(tglProduksi);

    // helper kecil biar "08:00" -> "08:00:00"
    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      // kalau cuma HH:mm tambahin :00
      if (t.length == 5) {
        return '$t:00';
      }
      return t;
    }

    // 🔴 PENTING: kirim sebagai MAP<String, String>
    final body = <String, String>{
      'tglProduksi': tglStr,
      'idMesin': idMesin.toString(),
      'idOperator': idOperator.toString(),
      'jam': jam.toString(),
      'shift': shift.toString(),
      if (hourStart != null && hourStart.isNotEmpty)
        'hourStart': _normalizeTime(hourStart),
      if (hourEnd != null && hourEnd.isNotEmpty)
        'hourEnd': _normalizeTime(hourEnd),
      if (checkBy1 != null) 'checkBy1': checkBy1,
      if (checkBy2 != null) 'checkBy2': checkBy2,
      if (approveBy != null) 'approveBy': approveBy,
      if (jmlhAnggota != null) 'jmlhAnggota': jmlhAnggota.toString(),
      if (hadir != null) 'hadir': hadir.toString(),
      if (hourMeter != null) 'hourMeter': hourMeter.toString(),
    };

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    print('➡️ [POST] $url');
    print('📦 form body: $body');

    late http.Response res;
    try {
      res = await http
          .post(
        url,
        headers: headers,
        body: body,
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout membuat broker produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal membuat broker produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal membuat broker produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return BrokerProduction.fromJson(data);
  }



  Future<BrokerProduction> updateProduksi({
    required String noProduksi,     // ← dari URL
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jam,                    // int atau 'HH:mm-HH:mm'
    int? shift,
    String? hourStart,
    String? hourEnd,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi');

    // helper sama kayak yang di create
    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) {
        return '$t:00'; // HH:mm -> HH:mm:00
      }
      return t;
    }

    // karena ini UPDATE, semua boleh null → kita kirim hanya yang diisi
    final body = <String, String>{};

    if (tglProduksi != null) {
      body['tglProduksi'] = toDbDateString(tglProduksi);
    }
    if (idMesin != null) {
      body['idMesin'] = idMesin.toString();
    }
    if (idOperator != null) {
      body['idOperator'] = idOperator.toString();
    }
    if (jam != null) {
      body['jam'] = jam.toString();
    }
    if (shift != null) {
      body['shift'] = shift.toString();
    }
    if (hourStart != null && hourStart.isNotEmpty) {
      body['hourStart'] = _normalizeTime(hourStart);
    }
    if (hourEnd != null && hourEnd.isNotEmpty) {
      body['hourEnd'] = _normalizeTime(hourEnd);
    }
    if (checkBy1 != null) {
      body['checkBy1'] = checkBy1;
    }
    if (checkBy2 != null) {
      body['checkBy2'] = checkBy2;
    }
    if (approveBy != null) {
      body['approveBy'] = approveBy;
    }
    if (jmlhAnggota != null) {
      body['jmlhAnggota'] = jmlhAnggota.toString();
    }
    if (hadir != null) {
      body['hadir'] = hadir.toString();
    }
    if (hourMeter != null) {
      body['hourMeter'] = hourMeter.toString();
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    print('➡️ [PUT] $url');
    print('📦 form body: $body');

    late http.Response res;
    try {
      res = await http
          .put(
        url,
        headers: headers,
        body: body,
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengubah broker produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal mengubah broker produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal mengubah broker produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return BrokerProduction.fromJson(data);
  }


  Future<void> deleteProduksi(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/broker/$noProduksi');

    print('🗑️ [DELETE] $url');

    late http.Response res;
    try {
      res = await http
          .delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout menghapus broker produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal menghapus broker produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal menghapus broker produksi (${res.statusCode})');
      }
    }

    // kalau sebelumnya kita sudah pernah ambil inputs untuk noProduksi ini, buang dari cache
    _inputsCache.remove(noProduksi);
  }




}

