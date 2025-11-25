// lib/features/shared/washing_production/washing_production_repository.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../model/washing_inputs_model.dart';
import '../model/washing_production_model.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

class WashingProductionRepository {
  static const _timeout = Duration(seconds: 25);

  // Simple in-memory cache for inputs
  final Map<String, WashingInputs> _inputsCache = {};

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
      'items': items, // List<WashingProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
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

// ==========================================
//  CREATE (POST /washing)
// ==========================================
  Future<WashingProduction> createProduksi({
    required DateTime tglProduksi,
    required int idMesin,
    required int idOperator,
    /// Bisa int (jam) atau string "HH:mm-HH:mm"
    required dynamic jamKerja,
    required int shift,
    String? checkBy1,
    String? checkBy2,
    String? approveBy,
    int? jmlhAnggota,
    int? hadir,
    double? hourMeter,

    // ⬇️ baru: ikutkan jam mulai & selesai
    String? hourStart,   // format kirim: 'HH:mm:00' atau 'HH:mm'
    String? hourEnd,     // format kirim: 'HH:mm:00' atau 'HH:mm'
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing');

    final payload = <String, dynamic>{
      'tglProduksi': toDbDateString(tglProduksi), // 'YYYY-MM-DD'
      'idMesin': idMesin,
      'idOperator': idOperator,
      'jamKerja': jamKerja,
      'shift': shift,
      if (checkBy1 != null) 'checkBy1': checkBy1,
      if (checkBy2 != null) 'checkBy2': checkBy2,
      if (approveBy != null) 'approveBy': approveBy,
      if (jmlhAnggota != null) 'jmlhAnggota': jmlhAnggota,
      if (hadir != null) 'hadir': hadir,
      if (hourMeter != null) 'hourMeter': hourMeter,
      // ⬇️ baru: ikutkan ke body kalau ada
      if (hourStart != null) 'hourStart': hourStart,
      if (hourEnd != null) 'hourEnd': hourEnd,
    };

    final started = DateTime.now();
    print('➡️ [POST] $url');
    print('   payload: $payload');

    late http.Response res;
    try {
      res = await http
          .post(
        url,
        headers: {
          ..._headers(token),
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout membuat washing produksi');
    } catch (e) {
      print('❌ Request error (create washing): $e');
      rethrow;
    }

    print(
      '⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms',
    );

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded);

    if (res.statusCode != 201) {
      // coba ambil pesan error dari body
      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }
      throw Exception('Gagal membuat washing produksi (${res.statusCode})');
    }

    if (body is! Map || body['data'] == null) {
      throw Exception('Response create washing tidak valid');
    }

    final data = body['data'] as Map<String, dynamic>;
    return WashingProduction.fromJson(data);
  }



  Future<WashingProduction> updateProduksi({
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
    final url = Uri.parse('$_base/api/production/washing/$noProduksi');

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

    return WashingProduction.fromJson(data);
  }



  Future<void> deleteProduksi(String noProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/washing/$noProduksi');

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
      final bodyText = utf8.decode(res.bodyBytes);
      print('❌ Error body: $bodyText');

      try {
        final decoded = json.decode(bodyText);

        String msg;

        if (decoded is Map<String, dynamic>) {
          // coba beberapa kemungkinan key
          msg = (decoded['message'] ??
              decoded['error'] ??
              decoded['msg'] ??
              'Gagal menghapus broker produksi')
              .toString();
        } else {
          // kalau backend kirim string langsung / array, pakai saja isinya
          msg = decoded.toString();
        }

        throw Exception(msg);
      } catch (e) {
        // kalau JSON.parse gagal total, pakai body apa adanya
        if (bodyText.isNotEmpty) {
          throw Exception(bodyText);
        }
        throw Exception('Gagal menghapus broker produksi (${res.statusCode})');
      }
    }

    // kalau sebelumnya kita sudah pernah ambil inputs untuk noProduksi ini, buang dari cache
    _inputsCache.remove(noProduksi);
  }


}
