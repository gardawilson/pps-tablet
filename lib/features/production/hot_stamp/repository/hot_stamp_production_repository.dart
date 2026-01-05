// lib/features/shared/hot_stamp_production/hot_stamp_production_repository.dart

import 'dart:async';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/hot_stamp_production_model.dart';


class HotStampProductionRepository {
  final ApiClient api;

  HotStampProductionRepository({ApiClient? api})
      : api = api ?? ApiClient();

  /// Get HotStamping_h by date
  /// Backend: GET /api/production/hot-stamp/:date (YYYY-MM-DD)
  Future<List<HotStampProduction>> fetchByDate(DateTime date) async {
    final dateDb = toDbDateString(date); // yyyy-MM-dd

    final Map<String, dynamic> body =
    await api.getJson('/api/production/hot-stamp/$dateDb');

    final List list = (body['data'] ?? []) as List;

    return list
        .map((e) => HotStampProduction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==========================================
  //  PAGINATED LIST
  //  GET /api/production/hot-stamp
  //  return: { items, page, totalPages, total }
  // ==========================================
  Future<Map<String, dynamic>> fetchAll({
    required int page,
    int pageSize = 20,
    String? search,
    String? noProduksi,
  }) async {
    // Prefer explicit noProduksi over generic search
    final String? effectiveSearch =
    (noProduksi != null && noProduksi.trim().isNotEmpty)
        ? noProduksi.trim()
        : (search != null && search.trim().isNotEmpty
        ? search.trim()
        : null);

    final qp = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (effectiveSearch != null) 'search': effectiveSearch,
    };

    final body = await api.getJson('/api/production/hot-stamp', query: qp);

    final List dataList = (body['data'] ?? []) as List;
    final items = dataList
        .map((e) => HotStampProduction.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = (body['meta'] ?? {}) as Map<String, dynamic>;
    final currentPage = (meta['page'] ?? page) as int;
    final totalPages = (meta['totalPages'] ?? 1) as int;
    final totalData = (body['totalData'] ?? meta['total'] ?? 0) as int;

    print(
        '✅ HotStamp parsed ${items.length} items (page $currentPage/$totalPages, total: $totalData)');

    return {
      'items': items, // List<HotStampProduction>
      'page': currentPage, // int
      'totalPages': totalPages, // int
      'total': totalData, // int
    };
  }

  /// Convenience jika hanya butuh list halaman tertentu
  Future<List<HotStampProduction>> fetchAllList({
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
    return (r['items'] as List<HotStampProduction>);
  }

  // =========================
  //  CREATE (POST)
  //  POST /api/production/hot-stamp
  //  DENGAN kolom jam (int atau 'HH:mm-HH:mm')
  // =========================
  Future<HotStampProduction> createProduksi({
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
    double? hourMeter,
  }) async {
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

    final payload = <String, dynamic>{
      'tglProduksi': tglStr,
      'idMesin': idMesin,
      'idOperator': idOperator,
      'jam': jam, // Backend parse int atau 'HH:mm-HH:mm'
      'shift': shift,
      if (hourStart != null && hourStart.isNotEmpty)
        'hourStart': _normalizeTime(hourStart),
      if (hourEnd != null && hourEnd.isNotEmpty)
        'hourEnd': _normalizeTime(hourEnd),
      if (checkBy1 != null) 'checkBy1': checkBy1,
      if (checkBy2 != null) 'checkBy2': checkBy2,
      if (approveBy != null) 'approveBy': approveBy,
      if (hourMeter != null) 'hourMeter': hourMeter,
    };

    print('📦 Hot stamp create payload: $payload');

    final body = await api.postJson('/api/production/hot-stamp', body: payload);

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header hot stamp');
    }

    return HotStampProduction.fromJson(data);
  }

  // =========================
  //  UPDATE (PUT)
  //  PUT /api/production/hot-stamp/:noProduksi
  //  DENGAN jam, partial update (kirim hanya yang diubah)
  // =========================
  Future<HotStampProduction> updateProduksi({
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
    double? hourMeter,
  }) async {
    String _normalizeTime(String v) {
      final t = v.trim();
      if (t.isEmpty) return t;
      if (t.length == 5) {
        return '$t:00'; // HH:mm -> HH:mm:00
      }
      return t;
    }

    final payload = <String, dynamic>{};

    if (tglProduksi != null) {
      payload['tglProduksi'] = toDbDateString(tglProduksi);
    }
    if (idMesin != null) {
      payload['idMesin'] = idMesin;
    }
    if (idOperator != null) {
      payload['idOperator'] = idOperator;
    }
    if (jam != null) {
      payload['jam'] = jam;
    }
    if (shift != null) {
      payload['shift'] = shift;
    }
    if (hourStart != null && hourStart.isNotEmpty) {
      payload['hourStart'] = _normalizeTime(hourStart);
    }
    if (hourEnd != null && hourEnd.isNotEmpty) {
      payload['hourEnd'] = _normalizeTime(hourEnd);
    }
    if (checkBy1 != null) {
      payload['checkBy1'] = checkBy1;
    }
    if (checkBy2 != null) {
      payload['checkBy2'] = checkBy2;
    }
    if (approveBy != null) {
      payload['approveBy'] = approveBy;
    }
    if (hourMeter != null) {
      payload['hourMeter'] = hourMeter;
    }

    print('📦 Hot stamp update payload: $payload');

    final body = await api.putJson(
      '/api/production/hot-stamp/$noProduksi',
      body: payload,
    );

    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Response tidak mengandung data header hot stamp');
    }

    return HotStampProduction.fromJson(data);
  }

  // =========================
  //  DELETE
  //  DELETE /api/production/hot-stamp/:noProduksi
  // =========================
  Future<void> deleteProduksi(String noProduksi) async {
    print('🗑️ Deleting hot stamp production: $noProduksi');

    try {
      await api.deleteJson('/api/production/hot-stamp/$noProduksi');
      print('✅ Hot stamp production deleted successfully');
    } catch (e) {
      print('❌ Delete hot stamp production error: $e');

      // Extract user-friendly message from ApiException
      if (e is ApiException) {
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            final msg = decoded['message'] ??
                decoded['error'] ??
                decoded['msg'] ??
                'Gagal menghapus hot stamp produksi';
            throw Exception(msg);
          } catch (_) {
            throw Exception(e.responseBody);
          }
        }
        throw Exception('Gagal menghapus hot stamp produksi (${e.statusCode})');
      }

      rethrow;
    }
  }
}