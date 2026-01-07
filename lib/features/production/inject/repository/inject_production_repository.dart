import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/core/utils/date_formatter.dart';

import '../model/inject_production_model.dart';
import '../model/furniture_wip_by_inject_production_model.dart';
import '../model/packing_by_inject_production_model.dart';

class InjectProductionRepository {
  final ApiClient api;

  InjectProductionRepository({ApiClient? apiClient})
      : api = apiClient ?? ApiClient();

  /* =============================
   * GET (BY DATE) - existing
   * ============================= */

  /// 🔹 Fetch InjectProduksi_h by date (YYYY-MM-DD)
  /// Backend: GET /api/production/inject/:date
  Future<List<InjectProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // YYYY-MM-DD

    final Map<String, dynamic> body =
    await api.getJson('/api/production/inject/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .whereType<Map>()
        .map((e) => InjectProduction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /* =============================
   * GET ALL (PAGED) - new
   * ============================= */

  static List<InjectProduction> _parsePagedList(Map<String, dynamic> body) {
    final data = body['data'];

    if (data == null) return <InjectProduction>[];
    if (data is! List) {
      throw FormatException('Response tidak valid: field data bukan List');
    }

    return data
        .whereType<Map>()
        .map((e) => InjectProduction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /api/production/inject?page=1&pageSize=20&search=S.0000
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "totalData": 123,
  ///   "data": [ ... ],
  ///   "meta": { page, pageSize, totalPages, hasNextPage, hasPrevPage, search }
  /// }
  Future<List<InjectProduction>> fetchPaged({
    int page = 1,
    int pageSize = 20,
    String search = '',
  }) async {
    final body = await api.getJson(
      '/api/production/inject',
      query: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    // parse in isolate (like HotStamp)
    return compute(_parsePagedList, body);
  }

  /* =============================
   * LOOKUP LISTS - existing
   * ============================= */

  /// 🔹 Fetch FurnitureWIP kandidat by NoProduksi Inject
  /// Backend: GET /api/production/inject/furniture-wip/:noProduksi
  Future<FurnitureWipByInjectResult> fetchFurnitureWipByInjectProduction(
      String noProduksi) async {
    final encodedNo = Uri.encodeComponent(noProduksi);

    try {
      final Map<String, dynamic> body = await api.getJson(
        '/api/production/inject/furniture-wip/$encodedNo',
      );

      // Normal (200 OK)
      return FurnitureWipByInjectResult.fromEnvelope(body);
    } on ApiException catch (e) {
      // ✅ 404 = "tidak ada data", jangan dianggap error
      if (e.statusCode == 404) {
        return const FurnitureWipByInjectResult(
          beratProdukHasilTimbang: null,
          items: <FurnitureWipByInjectItem>[],
        );
      }
      rethrow;
    }
  }

  /// 🔹 Fetch Packing (BarangJadi) kandidat by NoProduksi Inject
  /// Backend: GET /api/production/inject/packing/:noProduksi
  Future<PackingByInjectResult> fetchPackingByInjectProduction(
      String noProduksi) async {
    final encodedNo = Uri.encodeComponent(noProduksi);

    try {
      final Map<String, dynamic> body = await api.getJson(
        '/api/production/inject/packing/$encodedNo',
      );

      return PackingByInjectResult.fromEnvelope(body);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const PackingByInjectResult(
          beratProdukHasilTimbang: null,
          items: <PackingByInjectItem>[],
        );
      }
      rethrow;
    }
  }

  /* =============================
   * CRUD HEADER (Create / Update / Delete) - new
   * ============================= */

  /// POST /api/production/inject
  ///
  /// payload minimal (contoh):
  /// {
  ///   "tglProduksi":"2026-01-06",
  ///   "idMesin":27,
  ///   "idOperator":61,
  ///   "shift":1,
  ///   "jam":"09:00",
  ///   "hourStart":"09:00",
  ///   "hourEnd":"10:00"
  /// }
  Future<Map<String, dynamic>> createProduksi(
      Map<String, dynamic> payload) async {
    final path = '/api/production/inject';

    try {
      final body = await api.postJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal create InjectProduksi (HTTP ${e.statusCode})';

      if (e.statusCode == 422) {
        throw Exception(msg.isNotEmpty ? msg : 'Beberapa data tidak valid');
      }
      if (e.statusCode == 400) {
        throw Exception(msg.isNotEmpty ? msg : 'Request tidak valid');
      }

      throw Exception(msg);
    }
  }

  /// PUT /api/production/inject/:noProduksi
  Future<Map<String, dynamic>> updateProduksi(
      String noProduksi,
      Map<String, dynamic> payload,
      ) async {
    final no = noProduksi.trim();
    if (no.isEmpty) throw ArgumentError('noProduksi tidak boleh kosong');

    final path = '/api/production/inject/${Uri.encodeComponent(no)}';

    try {
      final body = await api.putJson(path, body: payload);
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);
      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal update InjectProduksi (HTTP ${e.statusCode})';

      if (e.statusCode == 422) {
        throw Exception(msg.isNotEmpty ? msg : 'Beberapa data tidak valid');
      }
      if (e.statusCode == 400) {
        throw Exception(msg.isNotEmpty ? msg : 'Request tidak valid');
      }

      throw Exception(msg);
    }
  }

  /// DELETE /api/production/inject/:noProduksi
  Future<Map<String, dynamic>> deleteProduksi(String noProduksi) async {
    final no = noProduksi.trim();
    if (no.isEmpty) throw ArgumentError('noProduksi tidak boleh kosong');

    final path = '/api/production/inject/${Uri.encodeComponent(no)}';

    try {
      final body = await api.deleteJson(path);

      // kalau backend kamu return {success,message} maka body ada isinya
      // kalau kosong pun tidak masalah
      return body;
    } on ApiException catch (e) {
      final parsed = _tryDecodeMap(e.responseBody);

      // 404 -> tetap return untuk UI (warning)
      if (e.statusCode == 404) {
        return parsed;
      }

      final msg = (parsed['message'] as String?) ??
          e.message ??
          'Gagal delete InjectProduksi (HTTP ${e.statusCode})';

      if (e.statusCode == 400) {
        throw Exception(msg.isNotEmpty ? msg : 'Request delete tidak valid');
      }

      throw Exception(msg);
    }
  }

  /* =============================
   * Helpers
   * ============================= */

  Map<String, dynamic> _tryDecodeMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'data': decoded};
    } catch (_) {
      return <String, dynamic>{'message': raw};
    }
  }
}
