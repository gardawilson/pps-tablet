import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/crusher_production_model.dart';

class CrusherProductionRepository {
  static const _timeout = Duration(seconds: 25);

  // Simple in-memory cache for inputs (if needed later)
  // final Map<String, CrusherInputs> _inputsCache = {};

  String get _base => ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');

  Map<String, String> _headers(String? token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  // =========================
  //  BY DATE (untuk dropdown/filter)
  // =========================
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

  // ==========================================
  //  PAGINATED LIST (infinite scroll style)
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,

    // Text search for NoCrusherProduksi (contains)
    String? search,

    // VM convenience: prefer this if provided
    String? noCrusherProduksi,
    bool exactNoCrusherProduksi = false, // backend currently does LIKE only

    // Other optional filters (supported by backend)
    int? shift,
    DateTime? date,               // legacy single date -> maps to dateFrom/dateTo
    DateTime? dateFrom,
    DateTime? dateTo,
    int? idMesin,
    int? idOperator,
  }) async {
    final token = await TokenStorage.getToken();

    // Prefer explicit noCrusherProduksi over generic search
    final String? effectiveSearch = (noCrusherProduksi != null && noCrusherProduksi.trim().isNotEmpty)
        ? noCrusherProduksi.trim()
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
      if (effectiveSearch != null) 'search': effectiveSearch, // API searches NoCrusherProduksi
      if (shift != null) 'shift': '$shift',
      if (df != null) 'dateFrom': df,
      if (dt != null) 'dateTo': dt,
      if (idMesin != null) 'idMesin': '$idMesin',
      if (idOperator != null) 'idOperator': '$idOperator',
    };

    final url = Uri.parse('$_base/api/production/crusher').replace(queryParameters: qp);

    final started = DateTime.now();
    print('➡️ [GET] $url');

    late http.Response res;
    try {
      res = await http.get(url, headers: _headers(token)).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout mengambil list crusher produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] in ${DateTime.now().difference(started).inMilliseconds}ms');

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil list crusher produksi (${res.statusCode})');
    }

    final decoded = utf8.decode(res.bodyBytes);
    final body = json.decode(decoded) as Map<String, dynamic>;

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => CrusherProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print('✅ Crusher parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items,           // List<CrusherProduction>
      'page': currentPage,      // int
      'totalPages': totalPages, // int
      'total': totalData,       // int
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<CrusherProduction>> fetchAllList({
    required int page,
    int pageSize = 20,
    String? search,
    String? noCrusherProduksi,
    bool exactNoCrusherProduksi = false,
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
      noCrusherProduksi: noCrusherProduksi,
      exactNoCrusherProduksi: exactNoCrusherProduksi,
      shift: shift,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
      idMesin: idMesin,
      idOperator: idOperator,
    );
    return (r['items'] as List<CrusherProduction>);
  }

// =========================
//  CREATE (POST)
// =========================

  Future<CrusherProduction> createProduksi({
    required DateTime tanggal,
    required int idMesin,
    required int idOperator,
    required int jamKerja,
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
    final url = Uri.parse('$_base/api/production/crusher');

    final tanggalStr = toDbDateString(tanggal);

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
      'tanggal': tanggalStr,
      'idMesin': idMesin.toString(),
      'idOperator': idOperator.toString(),
      'jamKerja': jamKerja.toString(),
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
      throw Exception('Timeout membuat crusher produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 201 && res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal membuat crusher produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal membuat crusher produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return CrusherProduction.fromJson(data);
  }

// =========================
//  UPDATE (PUT)
// =========================
  Future<CrusherProduction> updateProduksi({
    required String noCrusherProduksi,     // ← dari URL
    DateTime? tanggal,
    int? idMesin,
    int? idOperator,
    int? jamKerja,
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
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi');

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

    if (tanggal != null) {
      body['tanggal'] = toDbDateString(tanggal);
    }
    if (idMesin != null) {
      body['idMesin'] = idMesin.toString();
    }
    if (idOperator != null) {
      body['idOperator'] = idOperator.toString();
    }
    if (jamKerja != null) {
      body['jamKerja'] = jamKerja.toString();
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
      throw Exception('Timeout mengubah crusher produksi');
    } catch (e) {
      print('❌ Request error: $e');
      rethrow;
    }

    print('⬅️ [${res.statusCode}] ${res.body}');

    if (res.statusCode != 200) {
      try {
        final decoded = json.decode(utf8.decode(res.bodyBytes));
        final msg = decoded['message'] ?? 'Gagal mengubah crusher produksi';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Gagal mengubah crusher produksi (${res.statusCode})');
      }
    }

    final decoded = utf8.decode(res.bodyBytes);
    final bodyJson = json.decode(decoded) as Map<String, dynamic>;
    final data = bodyJson['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Response tidak mengandung data header');
    }

    return CrusherProduction.fromJson(data);
  }


// =========================
//  DELETE
// =========================
  Future<void> deleteProduksi(String noCrusherProduksi) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('$_base/api/production/crusher/$noCrusherProduksi');

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
      throw Exception('Timeout menghapus crusher produksi');
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
              'Gagal menghapus crusher produksi')
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
        throw Exception('Gagal menghapus crusher produksi (${res.statusCode})');
      }
    }

    // kalau sebelumnya kita sudah pernah ambil inputs untuk noCrusherProduksi ini,
    // buang dari cache
    // _inputsCache.remove(noCrusherProduksi);
  }

}