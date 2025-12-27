// lib/features/shared/mixer_production/mixer_production_repository.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/utils/date_formatter.dart';

import '../model/mixer_production_model.dart';

class MixerProductionRepository {
  static const _timeout = Duration(seconds: 25);

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Get MixerProduksi_h by date
  /// Backend: GET /api/production/mixer/:date (YYYY-MM-DD)
  Future<List<MixerProduction>> fetchByDate(DateTime date) async {
    final token = await TokenStorage.getToken();
    final dateDb = toDbDateString(date); // yyyy-MM-dd
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

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/mixer
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
  }) async {
    final token = await TokenStorage.getToken();

    // Prefer explicit noProduksi over generic search
    final String? effectiveSearch =
    (noProduksi != null && noProduksi.trim().isNotEmpty)
        ? noProduksi.trim()
        : (search != null && search.trim().isNotEmpty
        ? search.trim()
        : null);

    final qp = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (effectiveSearch != null) 'search': effectiveSearch,
    };

    final url = Uri.parse('$_base/api/production/mixer').replace(
      queryParameters: qp,
    );

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil list mixer produksi');
    } catch (e) {
      print('❌ Request error (mixer list): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in '
        '${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil list mixer produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => MixerProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print(
        '✅ Mixer parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<MixerProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<MixerProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
  }) async {
    final r = await fetchAll(
      page: page,
      pageSize: pageSize,
      search: search,
      noProduksi: noProduksi,
    );
    return (r['items'] as List<MixerProduction>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/mixer
  //  DENGAN kolom jam (int atau 'HH:mm-HH:mm')
  // =========================
  Future<MixerProduction> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    required dynamic jam, // int atau String 'HH:mm-HH:mm'
    required int shift,
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
    final url = Uri.parse('$_base/api/production/mixer');

    final tglStr = toDbDateString(tglProduksi);

    // helper kecil biar "08:00" -> "08:00:00"
    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) {
        return '$t:00';
      }
      return t;
    }

    final body = <String, String>{
      'tglProduksi': tglStr,
      'idMesin': idMesin.toString(),
      'idOperator': idOperator.toString(),
      'jam': jam.toString(), // Backend parse int atau 'HH:mm-HH:mm'
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
    print('📦 form body (mixer create): $body');

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
      throw Exception('Timeout membuat mixer produksi');
    } catch (e) {
      print('❌ Request error (mixer create): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal membuat mixer produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal membuat mixer produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header mixer');
    }

    return MixerProduction.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  //  PUT /api/production/mixer/:noProduksi
  //  DENGAN jam, partial update (kirim hanya yang diubah)
  // =========================
  Future<MixerProduction> updateProduksi({
    required String noProduksi,
    DateTime? tglProduksi,
    int? idMesin,
    int? idOperator,
    dynamic jam, // int atau String
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
    final url = Uri.parse('$_base/api/production/mixer/$noProduksi');

    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) {
        return '$t:00'; // HH:mm -> HH:mm:00
      }
      return t;
    }

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
    print('📦 form body (mixer update): $body');

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
      throw Exception('Timeout mengubah mixer produksi');
    } catch (e) {
      print('❌ Request error (mixer update): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal mengubah mixer produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal mengubah mixer produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header mixer');
    }

    return MixerProduction.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/mixer/:noProduksi
  // =========================
  Future<void> deleteProduksi(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/mixer/$noProduksi');

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
      throw Exception('Timeout menghapus mixer produksi');
    } catch (e) {
      print('❌ Request error (mixer delete): $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 200) {
      final bodyText = utf8.decode(res.bodyBytes);
      print('❌ Error body: $bodyText');

      try {
        final decoded = json.decode(bodyText);

        String msg;

        if (decoded is Map<String, dynamic>) {
          msg = (decoded['message'] ??
              decoded['error'] ??
              decoded['msg'] ??
              'Gagal menghapus mixer produksi')
              .toString();
        } else {
          msg = decoded.toString();
        }

        throw Exception(msg);
      } catch (e) {
        if (bodyText.isNotEmpty) {
          throw Exception(bodyText);
        }
        throw Exception('Gagal menghapus mixer produksi (${res.statusCode})');
      }
    }
  }
}